import React, { useState } from 'react';
import { Plane, Info } from 'lucide-react';
import { FlightFilter, Airport, ValidationError } from '../../types/flight-filter';
import ResponsiveAirportAutocomplete from '../ResponsiveAirportAutocomplete';
import FlightPriceCalendar, {
  FlightPriceCalendarDate,
  FlightPriceCalendarMode,
  FlightPriceCalendarSelection,
} from '../FlightPriceCalendar';

interface Step1RouteDatesProps {
  filter: FlightFilter;
  updateFilter: (updates: Partial<FlightFilter>) => void;
  errors: ValidationError[];
  calendarDates?: FlightPriceCalendarDate[];
  calendarPriceRange?: { min: number; max: number };
  onCalendarApply?: (
    selection: FlightPriceCalendarSelection & { mode: FlightPriceCalendarMode },
  ) => void;
}

const Step1RouteDates: React.FC<Step1RouteDatesProps> = ({
  filter,
  updateFilter,
  errors,
  calendarDates = [],
  calendarPriceRange,
  onCalendarApply,
}) => {
  const [originSearch, setOriginSearch] = useState('');
  const [destinationSearch, setDestinationSearch] = useState('');

  // Initialize search values when airports are selected
  React.useEffect(() => {
    if (filter.origin) {
      setOriginSearch(`${filter.origin.iata_code} - ${filter.origin.city}`);
    }
    if (filter.destination) {
      setDestinationSearch(`${filter.destination.iata_code} - ${filter.destination.city}`);
    }
  }, [filter.origin, filter.destination]);

  const handleOriginSelect = (airport: Airport | null) => {
    updateFilter({ origin: airport });
  };

  const handleDestinationSelect = (airport: Airport | null) => {
    updateFilter({ destination: airport });
  };

  const getError = (field: string) => {
    return errors.find(error => error.field === field)?.message;
  };

  const handleCalendarSelection = (
    selection: FlightPriceCalendarSelection,
  ) => {
    updateFilter({
      departureDate: selection.departure,
      returnDate: filter.tripType === 'round-trip' ? selection.return : null,
    });
  };

  const handleCalendarApply = (
    selection: FlightPriceCalendarSelection & { mode: FlightPriceCalendarMode },
  ) => {
    onCalendarApply?.(selection);
    updateFilter({
      flexibleDates: selection.mode === 'flexible',
    });
  };

  return (
    <div className="space-y-8">
      {/* Trip Type */}
      <div>
        <h3 className="text-lg font-semibold text-[#4C1D95] mb-4 uppercase tracking-wide">
          Trip Type
        </h3>
        <div className="grid grid-cols-3 gap-3">
          {(['one-way', 'round-trip', 'multi-city'] as const).map((type) => (
            <button
              key={type}
              onClick={() => updateFilter({ tripType: type })}
              className={`p-4 rounded-xl border-2 transition-all duration-200 ${
                filter.tripType === type
                  ? 'border-transparent bg-gradient-to-br from-[#8B5CF6] via-[#7C3AED] to-[#6B21A8] text-white shadow-lg shadow-[#5B21B650]'
                  : 'border-[#E9D5FF] bg-white text-[#4C1D95] hover:border-[#C4B5FD]'
              }`}
            >
              <div className="text-sm font-medium capitalize">{type.replace('-', ' ')}</div>
            </button>
          ))}
        </div>
      </div>

      {/* Route Selection */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Origin */}
        <ResponsiveAirportAutocomplete
          value={originSearch}
          onChange={setOriginSearch}
          onSelect={handleOriginSelect}
          placeholder="Search origin airports..."
          label="Origin Airport"
          error={getError('origin')}
          selectedAirport={filter.origin}
          showPopularAirports={true}
        />

        {/* Destination */}
        <ResponsiveAirportAutocomplete
          value={destinationSearch}
          onChange={setDestinationSearch}
          onSelect={handleDestinationSelect}
          placeholder="Search destination airports..."
          label="Destination Airport"
          error={getError('destination')}
          selectedAirport={filter.destination}
          showPopularAirports={true}
        />
      </div>

      {/* Price-Driven Calendar */}
      <div className="relative -mx-1 sm:mx-0">
        <FlightPriceCalendar
          availableDates={calendarDates}
          selectedDeparture={filter.departureDate}
          selectedReturn={filter.tripType === 'round-trip' ? filter.returnDate : null}
          onDateSelect={(selection) => handleCalendarSelection(selection)}
          minDate={new Date()}
          priceRange={calendarPriceRange}
          defaultMode={filter.flexibleDates ? 'flexible' : 'specific'}
          onModeChange={(mode) =>
            updateFilter({
              flexibleDates: mode === 'flexible',
            })
          }
          onApply={handleCalendarApply}
        />

        {(getError('departureDate') || getError('returnDate')) && (
          <div className="mt-3 space-y-1">
            {getError('departureDate') && (
              <p className="text-sm text-rose-200">{getError('departureDate')}</p>
            )}
            {filter.tripType === 'round-trip' && getError('returnDate') && (
              <p className="text-sm text-rose-200">{getError('returnDate')}</p>
            )}
          </div>
        )}
      </div>

      {/* Flexible Dates */}
      <div className="rounded-xl border border-[#C4B5FD]/50 bg-gradient-to-r from-[#F5F3FF]/80 via-[#DDD6FE]/60 to-[#C4B5FD]/40 p-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center">
            <input
              type="checkbox"
              id="flexibleDates"
              checked={filter.flexibleDates}
              onChange={(e) => updateFilter({ flexibleDates: e.target.checked })}
              className="h-4 w-4 rounded border-[#C4B5FD] text-[#8B5CF6] focus:ring-[#8B5CF6]"
            />
            <label htmlFor="flexibleDates" className="ml-2 text-sm font-semibold text-[#4C1D95]">
              Flexible ± Range
            </label>
          </div>
          
          {filter.flexibleDates && (
            <div className="flex items-center space-x-2">
              <span className="text-sm text-[#4C1D95]/80">±</span>
              <select
                value={filter.dateFlexibility}
                onChange={(e) => updateFilter({ dateFlexibility: parseInt(e.target.value) })}
                className="rounded-md border border-[#C4B5FD] bg-white/70 px-3 py-1 text-sm text-[#4C1D95] focus:border-[#8B5CF6] focus:ring-2 focus:ring-[#C4B5FD]"
              >
                <option value={1}>1 day</option>
                <option value={2}>2 days</option>
                <option value={3}>3 days</option>
                <option value={7}>1 week</option>
              </select>
            </div>
          )}
        </div>
        
        <div className="mt-2 flex items-start">
          <Info className="w-4 h-4 flex-shrink-0 text-[#8B5CF6] mr-2 mt-0.5" />
          <p className="text-sm text-[#4C1D95]">
            {filter.flexibleDates 
              ? `We'll search for flights within ±${filter.dateFlexibility} days of your preferred dates to find better prices.`
              : 'Enable flexible dates to search for flights within a few days of your preferred dates, often resulting in better prices.'
            }
          </p>
        </div>
      </div>

      {/* Route Summary */}
      {filter.origin && filter.destination && (
        <div className="rounded-xl border border-[#14B8A6]/40 bg-gradient-to-r from-[#0ea5e980]/20 via-[#06B6D4]/10 to-transparent p-4 text-[#0F172A] shadow-inner">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="h-3 w-3 rounded-full bg-[#14B8A6]" />
              <span className="font-semibold text-[#0f172a]">
                Route: {filter.origin.iata_code} → {filter.destination.iata_code}
              </span>
            </div>
            <span className="text-sm font-medium text-[#0f172a]/70">
              {filter.tripType.replace('-', ' ').replace(/\b\w/g, l => l.toUpperCase())}
            </span>
          </div>
          
          {filter.departureDate && (
            <div className="mt-2 text-sm text-[#0f172a]/80">
              Departure: {filter.departureDate.toLocaleDateString()}
              {filter.returnDate && ` • Return: ${filter.returnDate.toLocaleDateString()}`}
              {filter.flexibleDates && ` • ±${filter.dateFlexibility} days flexible`}
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default Step1RouteDates;
