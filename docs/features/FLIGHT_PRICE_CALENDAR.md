# Flight Price Calendar

## Overview

The `FlightPriceCalendar` React component renders a two-month, price-aware calendar inspired by Skyscanner’s fare explorer and adapted to PriceBreak’s purple brand system. It uses Tailwind CSS, supports round-trip selection flows, and colour-codes each date based on the relative fare within a supplied price range.

## Key Features

- Two adjacent month views with smooth fade transitions
- Price-driven colour mapping using PriceBreak’s cyan → violet gradient ramp
- Roundtrip selection with range highlighting and keyboard navigation
- “Specific dates” vs “Flexible dates” toggle to mirror discovery flows
- Glassmorphism container that integrates with the existing purple gradients
- Accessibility affordances: ARIA labelling, focus management, disabled states

## Props

| Prop | Type | Required | Description |
|------|------|----------|-------------|
| `availableDates` | `FlightPriceCalendarDate[]` | ✅ | Calendar entries with ISO date strings or `Date` objects and associated fares. Unspecified dates render as inactive. |
| `minDate` | `Date` | ❌ | Lower bound for selection. Past dates are disabled automatically. |
| `maxDate` | `Date` | ❌ | Upper bound for selection. |
| `selectedDeparture` | `Date \| null` | ❌ | Controlled value for the departure selection. Leave `undefined` for uncontrolled mode. |
| `selectedReturn` | `Date \| null` | ❌ | Controlled value for the return selection. Leave `undefined` for uncontrolled mode. |
| `onDateSelect` | `(selection, meta) => void` | ❌ | Fired whenever the user picks a new day. Receives the updated selection plus metadata about the active cursor. |
| `priceRange` | `{ min: number; max: number }` | ❌ | Override for the derived price range. When omitted, the component inspects `availableDates`. |
| `onApply` | `(selectionWithMode) => void` | ❌ | Invoked by the “Apply” CTA. Useful for saving and dismissing modals. |
| `defaultMode` | `"specific" \| "flexible"` | ❌ | Sets the initial toggle state. Defaults to `"specific"`. |
| `onModeChange` | `(mode) => void` | ❌ | Notifies consumers when the toggle is flipped. |
| `initialMonth` | `Date` | ❌ | Forces the left-month viewport. |
| `onMonthChange` | `(visibleMonth: Date) => void` | ❌ | Callback fired after month navigation. |
| `className` | `string` | ❌ | Tailwind utility passthrough for the root wrapper. |

Each `FlightPriceCalendarDate` is shaped as:

```ts
interface FlightPriceCalendarDate {
  date: string | Date;
  price: number;
  isAvailable?: boolean;
}
```

## Usage

```tsx
import React, { useState } from "react";
import FlightPriceCalendar, {
  FlightPriceCalendarDate,
  FlightPriceCalendarSelection,
} from "@/components/FlightPriceCalendar";

const mockDates: FlightPriceCalendarDate[] = [
  { date: "2025-11-01", price: 218 },
  { date: "2025-11-02", price: 244 },
  // ...
];

export default function CalendarDemo() {
  const [selection, setSelection] = useState<FlightPriceCalendarSelection>({
    departure: null,
    return: null,
  });

  return (
    <FlightPriceCalendar
      availableDates={mockDates}
      minDate={new Date()}
      selectedDeparture={selection.departure}
      selectedReturn={selection.return}
      onDateSelect={(next) => setSelection(next)}
      onApply={(payload) => console.log("Confirmed selection", payload)}
    />
  );
}
```

## Colour Ramp

| Price Level | Hex |
|-------------|-----|
| Lowest | `#06B6D4` |
| Low-medium | `#14B8A6` |
| Medium | `#A78BFA` |
| Medium-high | `#7C3AED` |
| Highest | `#6B21A8` |

The component normalises the supplied price range and picks a colour bucket based on the percentile. When the range collapses to a single value, it defaults to the brand mid-tone `#8B5CF6`.

## Accessibility Notes

- All date buttons expose human-readable labels (`weekday, month day`) and include prices where available.
- Keyboard navigation supports arrow keys, <kbd>Enter</kbd>, and <kbd>Space</kbd>.
- Past dates, out-of-range dates, and days without price data are surfaced as disabled with semi-transparent styling to match the specification.


