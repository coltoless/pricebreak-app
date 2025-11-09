import React, {
  useMemo,
  useState,
  useEffect,
  useRef,
  useCallback,
} from "react";
import clsx from "clsx";
import { ChevronLeft, ChevronRight } from "lucide-react";

/**
 * Shape for individual date entries surfaced to the calendar.
 * Provide ISO strings or Date instances – they are normalized internally.
 */
export interface FlightPriceCalendarDate {
  date: string | Date;
  price: number;
  /**
   * Optional override to explicitly hide/disable a date even if it falls within min/max.
   * Defaults to true.
   */
  isAvailable?: boolean;
}

/**
 * Selection payload describing the currently chosen departure / return pairing.
 */
export interface FlightPriceCalendarSelection {
  departure: Date | null;
  return: Date | null;
}

export type FlightPriceCalendarMode = "specific" | "flexible";

export interface FlightPriceCalendarProps {
  /**
   * Dates with price metadata used to colorize the calendar.
   */
  availableDates: FlightPriceCalendarDate[];
  /**
   * Optional minimum selectable date. Past dates are disabled automatically.
   */
  minDate?: Date;
  /**
   * Optional maximum selectable date.
   */
  maxDate?: Date;
  /**
   * Controlled departure value. Falls back to internal state when undefined.
   */
  selectedDeparture?: Date | null;
  /**
   * Controlled return value. Falls back to internal state when undefined.
   */
  selectedReturn?: Date | null;
  /**
   * Fires whenever the user selects a day. Supplies the updated selection.
   */
  onDateSelect?: (
    selection: FlightPriceCalendarSelection,
    meta: {
      activeSelection: "departure" | "return";
      date: Date;
      triggeredBy: "user" | "reset";
    },
  ) => void;
  /**
   * External price range override. When omitted, the component derives min/max from `availableDates`.
   */
  priceRange?: {
    min: number;
    max: number;
  };
  /**
   * Fired when the primary CTA is pressed.
   */
  onApply?: (
    selection: FlightPriceCalendarSelection & { mode: FlightPriceCalendarMode },
  ) => void;
  /**
   * Sets the initial toggle mode and re-runs when the prop changes.
   */
  defaultMode?: FlightPriceCalendarMode;
  /**
   * Event fired when the Specific/Flexible toggle changes.
   */
  onModeChange?: (mode: FlightPriceCalendarMode) => void;
  /**
   * Override the initial month rendered on the left-hand side.
   */
  initialMonth?: Date;
  /**
   * Optional callback fired after navigating months.
   */
  onMonthChange?: (visibleMonth: Date) => void;
  /**
   * Tailwind-compatible className passthrough for the root wrapper.
   */
  className?: string;
}

const DAYS_OF_WEEK = ["S", "M", "T", "W", "T", "F", "S"];

const PURPLE_GRADIENT_CLASSES =
  "bg-gradient-to-br from-[#8B5CF6] via-[#7C3AED] to-[#6B21A8]";

const clampToStartOfDay = (value: Date) => {
  const cloned = new Date(value);
  cloned.setHours(0, 0, 0, 0);
  return cloned;
};

const parseToDate = (input: string | Date) => {
  const parsed = input instanceof Date ? input : new Date(input);
  return clampToStartOfDay(parsed);
};

const formatDateKey = (date: Date) => date.toISOString().split("T")[0];

const startOfMonth = (date: Date) =>
  new Date(date.getFullYear(), date.getMonth(), 1);

const addMonths = (date: Date, amount: number) =>
  new Date(date.getFullYear(), date.getMonth() + amount, 1);

const addDays = (date: Date, amount: number) =>
  new Date(date.getFullYear(), date.getMonth(), date.getDate() + amount);

const isSameDay = (left?: Date | null, right?: Date | null) =>
  !!left &&
  !!right &&
  left.getFullYear() === right.getFullYear() &&
  left.getMonth() === right.getMonth() &&
  left.getDate() === right.getDate();

const isBeforeDay = (left: Date, right: Date) =>
  left.getFullYear() === right.getFullYear()
    ? left.getMonth() === right.getMonth()
      ? left.getDate() < right.getDate()
      : left.getMonth() < right.getMonth()
    : left.getFullYear() < right.getFullYear();

const isAfterDay = (left: Date, right: Date) => isBeforeDay(right, left);

const getCalendarMatrix = (month: Date) => {
  const firstOfMonth = startOfMonth(month);
  const firstWeekday = firstOfMonth.getDay(); // Sunday = 0
  const startGrid = addDays(firstOfMonth, -firstWeekday);

  return Array.from({ length: 42 }, (_, index) => addDays(startGrid, index));
};

const deriveInitialMonth = (
  selection: FlightPriceCalendarSelection,
  availableDates: FlightPriceCalendarDate[],
  fallback: Date,
) => {
  const fallbackMonth = startOfMonth(fallback);
  if (selection.departure) {
    return startOfMonth(selection.departure);
  }

  const sortedAvailable = availableDates
    .map(({ date }) => parseToDate(date))
    .sort((a, b) => a.getTime() - b.getTime());

  if (sortedAvailable.length > 0) {
    return startOfMonth(sortedAvailable[0]);
  }

  return fallbackMonth;
};

const derivePriceRange = (
  availableDates: FlightPriceCalendarDate[],
  override?: { min: number; max: number },
) => {
  if (override) {
    return override;
  }

  if (!availableDates.length) {
    return { min: 0, max: 0 };
  }

  const prices = availableDates.map((item) => item.price);
  const minPrice = Math.min(...prices);
  const maxPrice = Math.max(...prices);

  return { min: minPrice, max: maxPrice };
};

const resolvePriceColor = (
  price: number,
  range: { min: number; max: number },
) => {
  if (range.max <= range.min) {
    return "#8B5CF6";
  }

  const ratio = (price - range.min) / (range.max - range.min);

  if (ratio <= 0.2) {
    return "#06B6D4"; // Bright cyan
  }

  if (ratio <= 0.4) {
    return "#14B8A6"; // Turquoise leaning
  }

  if (ratio <= 0.6) {
    return "#A78BFA"; // Light purple
  }

  if (ratio <= 0.8) {
    return "#7C3AED"; // Medium-high purple
  }

  return "#6B21A8"; // Deepest purple
};

const today = clampToStartOfDay(new Date());

const focusDate = (
  containerRef: React.RefObject<HTMLDivElement>,
  dateKey: string,
) => {
  if (!containerRef.current) {
    return;
  }

  const target = containerRef.current.querySelector<HTMLButtonElement>(
    `[data-date-key="${dateKey}"]`,
  );

  if (target) {
    target.focus();
  }
};

/**
 * PriceBreak inspired flight price calendar with rich price-based color coding
 * and roundtrip selection. Designed for reuse across dashboards or modal flows.
 */
const FlightPriceCalendar: React.FC<FlightPriceCalendarProps> = ({
  availableDates,
  minDate,
  maxDate,
  selectedDeparture,
  selectedReturn,
  onDateSelect,
  priceRange,
  onApply,
  defaultMode = "specific",
  onModeChange,
  initialMonth,
  onMonthChange,
  className,
}) => {
  const minSelectable = useMemo(() => {
    if (!minDate) {
      return today;
    }

    const normalized = clampToStartOfDay(minDate);
    return isBeforeDay(normalized, today) ? today : normalized;
  }, [minDate]);

  const maxSelectable = useMemo(
    () => (maxDate ? clampToStartOfDay(maxDate) : undefined),
    [maxDate],
  );

  const [internalSelection, setInternalSelection] =
    useState<FlightPriceCalendarSelection>({
      departure:
        selectedDeparture !== undefined ? selectedDeparture ?? null : null,
      return: selectedReturn !== undefined ? selectedReturn ?? null : null,
    });

  useEffect(() => {
    if (selectedDeparture !== undefined || selectedReturn !== undefined) {
      setInternalSelection((prev) => ({
        departure:
          selectedDeparture !== undefined
            ? selectedDeparture ?? null
            : prev.departure,
        return:
          selectedReturn !== undefined ? selectedReturn ?? null : prev.return,
      }));
    }
  }, [selectedDeparture, selectedReturn]);

  const departureValue =
    selectedDeparture !== undefined
      ? selectedDeparture
      : internalSelection.departure;
  const returnValue =
    selectedReturn !== undefined ? selectedReturn : internalSelection.return;

  const departure = departureValue ?? null;
  const returnDate = returnValue ?? null;

  const selection = useMemo<FlightPriceCalendarSelection>(
    () => ({
      departure,
      return: returnDate,
    }),
    [departure, returnDate],
  );

  const [activeSelection, setActiveSelection] = useState<
    "departure" | "return"
  >(() => {
    if (selection.departure && !selection.return) {
      return "return";
    }
    return "departure";
  });

  useEffect(() => {
    if (selection.departure && !selection.return) {
      setActiveSelection("return");
    } else if (!selection.departure) {
      setActiveSelection("departure");
    }
  }, [selection.departure, selection.return]);

  const [mode, setMode] = useState<FlightPriceCalendarMode>(defaultMode);

  useEffect(() => {
    setMode(defaultMode);
  }, [defaultMode]);

  const handleModeToggle = (nextMode: FlightPriceCalendarMode) => {
    setMode(nextMode);
    onModeChange?.(nextMode);
  };

  const derivedRange = useMemo(
    () => derivePriceRange(availableDates, priceRange),
    [availableDates, priceRange],
  );

  const availableByDate = useMemo(() => {
    const map = new Map<
      string,
      { price: number; isAvailable: boolean }
    >();

    availableDates.forEach((entry) => {
      const normalizedDate = parseToDate(entry.date);
      map.set(formatDateKey(normalizedDate), {
        price: entry.price,
        isAvailable: entry.isAvailable ?? true,
      });
    });

    return map;
  }, [availableDates]);

  const resolvedInitialMonth = useMemo(
    () =>
      startOfMonth(
        initialMonth ??
          deriveInitialMonth(
            selection,
            availableDates,
            minSelectable ?? today,
          ),
      ),
    [initialMonth, selection, availableDates, minSelectable],
  );

  const [visibleMonth, setVisibleMonth] = useState(resolvedInitialMonth);

  useEffect(() => {
    setVisibleMonth(resolvedInitialMonth);
  }, [resolvedInitialMonth]);

  const calendarGridRef = useRef<HTMLDivElement>(null);

  const handleMonthNavigation = (direction: "prev" | "next") => {
    setVisibleMonth((current) => {
      const nextMonth =
        direction === "prev" ? addMonths(current, -1) : addMonths(current, 1);
      onMonthChange?.(nextMonth);
      return nextMonth;
    });
  };

  const monthLeft = visibleMonth;
  const monthRight = addMonths(visibleMonth, 1);

  const minMonth = startOfMonth(minSelectable ?? today);
  const maxMonth = maxSelectable ? startOfMonth(maxSelectable) : undefined;

  const canGoPrev = !minMonth || !isBeforeDay(addMonths(monthLeft, -1), minMonth);
  const canGoNext =
    !maxMonth || !isAfterDay(addMonths(monthRight, 1), maxMonth);

  const handleSelectionChange = useCallback(
    (pickedDate: Date) => {
      const normalized = clampToStartOfDay(pickedDate);

      setInternalSelection((current) => {
        const nextSelection: FlightPriceCalendarSelection = {
          departure: current.departure,
          return: current.return,
        };

        let nextActive: "departure" | "return" = activeSelection;

        if (activeSelection === "departure") {
          nextSelection.departure = normalized;
          if (
            nextSelection.return &&
            isBeforeDay(nextSelection.return, normalized)
          ) {
            nextSelection.return = null;
          }
          nextActive = "return";
        } else {
          if (
            nextSelection.departure &&
            isAfterDay(normalized, nextSelection.departure)
          ) {
            nextSelection.return = normalized;
          } else if (
            nextSelection.departure &&
            isBeforeDay(normalized, nextSelection.departure)
          ) {
            nextSelection.return = nextSelection.departure;
            nextSelection.departure = normalized;
          } else {
            nextSelection.departure = normalized;
            nextSelection.return = null;
          }
          nextActive = "departure";
        }

        setActiveSelection(nextActive);

        onDateSelect?.(
          {
            departure: nextSelection.departure,
            return: nextSelection.return,
          },
          {
            activeSelection: nextActive,
            date: normalized,
            triggeredBy: "user",
          },
        );

        return nextSelection;
      });
    },
    [activeSelection, onDateSelect],
  );

  const isDateDisabled = (date: Date, key: string) => {
    if (isBeforeDay(date, minSelectable)) {
      return true;
    }

    if (maxSelectable && isAfterDay(date, maxSelectable)) {
      return true;
    }

    const entry = availableByDate.get(key);
    if (!entry || !entry.isAvailable) {
      return true;
    }

    return false;
  };

  const handleDayKeyDown = (
    event: React.KeyboardEvent<HTMLButtonElement>,
    date: Date,
  ) => {
    const adjustments: Record<string, number> = {
      ArrowUp: -7,
      ArrowDown: 7,
      ArrowLeft: -1,
      ArrowRight: 1,
    };

    const amount = adjustments[event.key];

    if (amount) {
      event.preventDefault();
      const targetDate = addDays(date, amount);
      focusDate(calendarGridRef, formatDateKey(targetDate));
    }

    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      handleSelectionChange(date);
    }
  };

  const renderMonth = (month: Date) => {
    const calendarDays = getCalendarMatrix(month);

    return (
      <div
        key={`${month.getFullYear()}-${month.getMonth()}`}
        className="flex flex-col gap-3 rounded-2xl bg-white/5 p-4 backdrop-blur-xl transition-all duration-300 hover:bg-white/20"
      >
        <div className="text-sm font-semibold uppercase tracking-[0.2em] text-white/80">
          {month.toLocaleDateString(undefined, {
            month: "long",
            year: "numeric",
          })}
        </div>
        <div className="grid grid-cols-7 gap-2 text-[0.75rem] font-semibold uppercase tracking-wide text-white/50">
          {DAYS_OF_WEEK.map((day) => (
            <span key={day} className="flex h-10 items-center justify-center">
              {day}
            </span>
          ))}
        </div>
        <div
          className="grid grid-cols-7 gap-2"
          role="grid"
          aria-label={`${month.toLocaleDateString(undefined, {
            month: "long",
            year: "numeric",
          })} dates`}
        >
          {calendarDays.map((date) => {
            const key = formatDateKey(date);
            const entry = availableByDate.get(key);
            const isCurrentMonth = date.getMonth() === month.getMonth();
            const disabled = isDateDisabled(date, key) || !isCurrentMonth;
            const isDeparture = isSameDay(date, selection.departure);
            const isReturn = isSameDay(date, selection.return);
            const inRange =
              selection.departure &&
              selection.return &&
              isAfterDay(date, selection.departure) &&
              isBeforeDay(date, selection.return);

            const isSelected = isDeparture || isReturn;
            const isToday =
              date.getFullYear() === today.getFullYear() &&
              date.getMonth() === today.getMonth() &&
              date.getDate() === today.getDate();

            const priceColor =
              entry && !disabled
                ? resolvePriceColor(entry.price, derivedRange)
                : undefined;

            return (
              <div
                key={key}
                className={clsx(
                  "relative flex h-12 w-12 items-center justify-center md:h-14 md:w-14",
                  !isCurrentMonth && "opacity-40",
                  inRange && "z-0",
                )}
                role="gridcell"
                aria-selected={isSelected}
              >
                {inRange && (
                  <span className="absolute inset-1 rounded-full bg-white/15 blur-sm" />
                )}
                <button
                  type="button"
                  data-date-key={key}
                  onClick={() => !disabled && handleSelectionChange(date)}
                  onKeyDown={(event) => handleDayKeyDown(event, date)}
                  disabled={disabled}
                  className={clsx(
                    "relative flex h-full w-full items-center justify-center rounded-full text-sm font-semibold transition-all duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/80 focus-visible:ring-offset-2 focus-visible:ring-offset-transparent",
                    disabled
                      ? "cursor-not-allowed bg-white/10 text-white/40"
                      : "cursor-pointer text-white shadow-[0_10px_25px_rgba(20,18,33,0.25)] hover:scale-105 hover:shadow-[0_12px_30px_rgba(21,18,60,0.45)]",
                    isSelected &&
                      "bg-white text-[#7C3AED] shadow-[0_0_0_2px_rgba(255,255,255,0.8)] hover:scale-100 hover:shadow-[0_0_0_3px_rgba(255,255,255,0.9)]",
                  )}
                  aria-label={`${date.toLocaleDateString(undefined, {
                    weekday: "long",
                    month: "long",
                    day: "numeric",
                  })}${
                    entry ? ` – $${entry.price.toLocaleString()}` : ""
                  }${disabled ? " (Unavailable)" : ""}`}
                  aria-disabled={disabled}
                  aria-pressed={isSelected}
                  style={
                    !isSelected && !disabled && priceColor
                      ? {
                          background: priceColor,
                          boxShadow:
                            "0 12px 30px rgba(33, 20, 70, 0.35), 0 0 0 1px rgba(255,255,255,0.12)",
                        }
                      : undefined
                  }
                  title={
                    entry
                      ? `${date.toLocaleDateString(undefined, {
                          weekday: "long",
                          month: "long",
                          day: "numeric",
                        })} • $${entry.price.toLocaleString()}`
                      : date.toLocaleDateString()
                  }
                >
                  <span>{date.getDate()}</span>
                  {isToday && !isSelected && (
                    <span className="absolute bottom-1 left-1/2 h-1 w-1 -translate-x-1/2 rounded-full bg-white/70" />
                  )}
                </button>
              </div>
            );
          })}
        </div>
      </div>
    );
  };

  return (
    <div
      className={clsx(
        "relative w-full rounded-3xl p-[1px]",
        PURPLE_GRADIENT_CLASSES,
        className,
      )}
    >
      <div className="relative overflow-hidden rounded-[calc(theme(borderRadius.3xl)-1px)] bg-white/10 p-6 backdrop-blur-2xl shadow-[0_25px_65px_rgba(17,24,39,0.45)]">
        <div className="absolute inset-0 -z-10 bg-white/5 blur-[120px]" />
        <div className="mb-6 flex items-center justify-between gap-4">
          <div className="flex flex-col gap-1">
            <span className="text-xs uppercase tracking-[0.4em] text-white/50">
              PriceBreak
            </span>
            <h2 className="text-xl font-semibold text-white md:text-2xl">
              Flight Price Calendar
            </h2>
          </div>
          <div className="flex items-center gap-2 rounded-full bg-white/10 p-1 text-sm font-medium text-white shadow-inner">
            <button
              type="button"
              className={clsx(
                "rounded-full px-4 py-1.5 transition duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/80",
                mode === "specific"
                  ? "bg-white/25 text-white shadow-[0_12px_30px_rgba(138,92,246,0.45)]"
                  : "text-white/70 hover:text-white",
              )}
              onClick={() => handleModeToggle("specific")}
              aria-pressed={mode === "specific"}
            >
              Specific dates
            </button>
            <button
              type="button"
              className={clsx(
                "rounded-full px-4 py-1.5 transition duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/80",
                mode === "flexible"
                  ? "bg-white/25 text-white shadow-[0_12px_30px_rgba(138,92,246,0.45)]"
                  : "text-white/70 hover:text-white",
              )}
              onClick={() => handleModeToggle("flexible")}
              aria-pressed={mode === "flexible"}
            >
              Flexible dates
            </button>
          </div>
        </div>

        <div className="mb-4 flex items-center justify-between text-white/80">
          <button
            type="button"
            className={clsx(
              "flex h-11 w-11 items-center justify-center rounded-full bg-white/10 transition-all duration-200 hover:bg-white/20 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/80",
              !canGoPrev && "pointer-events-none opacity-40",
            )}
            onClick={() => canGoPrev && handleMonthNavigation("prev")}
            aria-label="Previous month"
          >
            <ChevronLeft className="h-5 w-5" />
          </button>
          <div className="text-center text-sm uppercase tracking-[0.3em]">
            {activeSelection === "departure" ? "Select departure" : "Select return"}
          </div>
          <button
            type="button"
            className={clsx(
              "flex h-11 w-11 items-center justify-center rounded-full bg-white/10 transition-all duration-200 hover:bg-white/20 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/80",
              !canGoNext && "pointer-events-none opacity-40",
            )}
            onClick={() => canGoNext && handleMonthNavigation("next")}
            aria-label="Next month"
          >
            <ChevronRight className="h-5 w-5" />
          </button>
        </div>

        <div
          ref={calendarGridRef}
          className="grid gap-6 md:grid-cols-2"
        >
          {renderMonth(monthLeft)}
          {renderMonth(monthRight)}
        </div>

        <div className="mt-6 flex flex-wrap items-center justify-between gap-4 text-xs text-white/70">
          <div className="flex flex-wrap items-center gap-3">
            <span className="flex items-center gap-2">
              <span className="inline-flex h-3 w-3 rounded-full bg-[#06B6D4]" />
              Lowest fares
            </span>
            <span className="flex items-center gap-2">
              <span className="inline-flex h-3 w-3 rounded-full bg-[#A78BFA]" />
              Balanced fares
            </span>
            <span className="flex items-center gap-2">
              <span className="inline-flex h-3 w-3 rounded-full bg-[#6B21A8]" />
              Premium fares
            </span>
          </div>

          <div className="flex items-center gap-2">
            <div className="rounded-full bg-white/10 px-3 py-2 text-xs uppercase tracking-wide text-white/70">
              {mode === "specific" ? "Roundtrip" : "Explore ranges"}
            </div>
            <button
              type="button"
              className="inline-flex items-center justify-center rounded-full bg-[#8B5CF6] px-5 py-2 text-sm font-semibold text-white shadow-[0_15px_35px_rgba(90,60,190,0.45)] transition hover:bg-[#A78BFA] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/80"
              onClick={() =>
                onApply?.({
                  ...selection,
                  mode,
                })
              }
            >
              Apply
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default FlightPriceCalendar;

