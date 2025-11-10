import React, { useState } from 'react';
import { Plane, Users, Clock, Info } from 'lucide-react';
import { FlightFilter, ValidationError } from '../../types/flight-filter';

interface Step2FlightPreferencesProps {
  filter: FlightFilter;
  updateFilter: (updates: Partial<FlightFilter>) => void;
  errors: ValidationError[];
}

const Step2FlightPreferences: React.FC<Step2FlightPreferencesProps> = ({ filter, updateFilter, errors }) => {
  const [showAirlineDropdown, setShowAirlineDropdown] = useState(false);
  const [airlineSearch, setAirlineSearch] = useState('');

  const airlines = [
    'Delta Air Lines', 'American Airlines', 'United Airlines', 'Southwest Airlines',
    'JetBlue Airways', 'Alaska Airlines', 'Spirit Airlines', 'Frontier Airlines',
    'British Airways', 'Lufthansa', 'Air France', 'KLM', 'Emirates', 'Qatar Airways'
  ];

  const timeSlots = [
    { value: 'morning', label: 'Morning (6AM - 12PM)', icon: '🌅' },
    { value: 'afternoon', label: 'Afternoon (12PM - 6PM)', icon: '☀️' },
    { value: 'evening', label: 'Evening (6PM - 12AM)', icon: '🌆' },
    { value: 'red-eye', label: 'Red-eye (12AM - 6AM)', icon: '🌙' }
  ];

  const cabinClasses = [
    { value: 'economy', label: 'Economy', description: 'Standard seating', price: 'Base' },
    { value: 'premium-economy', label: 'Premium Economy', description: 'Extra legroom', price: '+$50-150' },
    { value: 'business', label: 'Business', description: 'Premium service', price: '+$200-500' },
    { value: 'first', label: 'First Class', description: 'Luxury experience', price: '+$500+' }
  ];

  const stopOptions = [
    { value: 'nonstop', label: 'Nonstop', description: 'Direct flights only' },
    { value: '1-stop', label: '1 Stop', description: 'One connection max' },
    { value: '2+', label: '2+ Stops', description: 'Multiple connections OK' }
  ];

  const getError = (field: string) => {
    return errors.find(error => error.field === field)?.message;
  };

  const updatePassengers = (type: 'adults' | 'children' | 'infants', value: number) => {
    const newPassengers = { ...filter.passengers, [type]: Math.max(0, value) };
    updateFilter({ passengers: newPassengers });
  };

  const toggleAirline = (airline: string) => {
    const current = filter.airlinePreferences;
    const updated = current.includes(airline)
      ? current.filter(a => a !== airline)
      : [...current, airline];
    updateFilter({ airlinePreferences: updated });
  };

  const toggleTimePreference = (type: 'departure' | 'arrival', time: string) => {
    const current = filter.preferredTimes[type];
    const updated = current.includes(time as any)
      ? current.filter(t => t !== time)
      : [...current, time as any];
    updateFilter({ 
      preferredTimes: { 
        ...filter.preferredTimes, 
        [type]: updated 
      } 
    });
  };

  const filteredAirlines = airlines.filter(airline =>
    airline.toLowerCase().includes(airlineSearch.toLowerCase())
  );

  return (
    <div className="space-y-8">

      {/* Cabin Class */}
      <div className="rounded-xl border border-[#E9D5FF] bg-[#F5F3FF] p-4">
        <h3 className="mb-3 flex items-center font-semibold text-[#4C1D95]">
          <Plane className="w-4 h-4 mr-2 text-[#7C3AED]" />
          Cabin Class
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          {cabinClasses.map((cabin) => (
            <button
              key={cabin.value}
              onClick={() => updateFilter({ cabinClass: cabin.value as any })}
              className={`rounded-lg border-2 p-4 text-left transition-colors ${
                filter.cabinClass === cabin.value
                  ? 'border-transparent bg-gradient-to-br from-[#8B5CF6] via-[#7C3AED] to-[#6B21A8] text-white shadow-lg shadow-[#5B21B650]'
                  : 'border-[#E9D5FF] bg-white text-[#4C1D95] hover:border-[#C4B5FD]'
              }`}
            >
              <div className="font-medium">{cabin.label}</div>
              <div className={`text-sm ${filter.cabinClass === cabin.value ? 'text-white/80' : 'text-[#4C1D95]/70'}`}>
                {cabin.description}
              </div>
              <div className={`text-xs font-medium ${filter.cabinClass === cabin.value ? 'text-white/80' : 'text-[#7C3AED]'}`}>
                {cabin.price}
              </div>
            </button>
          ))}
        </div>
      </div>

      {/* Passengers */}
      <div className="rounded-xl border border-[#E9D5FF] bg-[#F5F3FF] p-4">
        <h3 className="mb-3 flex items-center font-semibold text-[#4C1D95]">
          <Users className="w-4 h-4 mr-2 text-[#7C3AED]" />
          Passengers
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {(['adults', 'children', 'infants'] as const).map((type) => (
            <div key={type} className="text-center">
              <label className="mb-2 block text-sm font-medium text-[#4C1D95] capitalize">
                {type}
              </label>
              <div className="flex items-center justify-center space-x-2">
                <button
                  onClick={() => updatePassengers(type, filter.passengers[type] - 1)}
                  disabled={filter.passengers[type] === 0}
                  className="flex h-8 w-8 items-center justify-center rounded-full bg-white text-[#4C1D95] shadow-inner shadow-white/40 hover:bg-[#EDE9FE] disabled:cursor-not-allowed disabled:opacity-50"
                >
                  -
                </button>
                <span className="w-12 text-center font-medium text-lg">
                  {filter.passengers[type]}
                </span>
                <button
                  onClick={() => updatePassengers(type, filter.passengers[type] + 1)}
                  className="flex h-8 w-8 items-center justify-center rounded-full bg-gradient-to-br from-[#8B5CF6] to-[#6B21A8] text-white shadow-lg shadow-[#6B21A850] hover:scale-[1.05]"
                >
                  +
                </button>
              </div>
              {type === 'infants' && (
                <p className="mt-1 text-xs text-[#4C1D95]/70">
                  Must be under 2 years old
                </p>
              )}
            </div>
          ))}
        </div>
        
        {getError('passengers') && (
          <p className="mt-3 text-sm text-red-600 text-center">{getError('passengers')}</p>
        )}
      </div>

      {/* Airline Preferences */}
      <div className="rounded-xl border border-[#E9D5FF] bg-[#F5F3FF] p-4">
        <h3 className="mb-3 font-semibold text-[#4C1D95]">Airline Preferences</h3>
        <div className="relative mb-3">
          <input
            type="text"
            value={airlineSearch}
            onChange={(e) => {
              setAirlineSearch(e.target.value);
              setShowAirlineDropdown(true);
            }}
            onFocus={() => setShowAirlineDropdown(true)}
            placeholder="Search airlines..."
            className="w-full rounded-lg border border-[#E9D5FF] bg-white px-4 py-2 text-[#4C1D95] focus:border-[#C4B5FD] focus:ring-2 focus:ring-[#C4B5FD]"
          />
          
          {showAirlineDropdown && (
            <div className="absolute z-10 mt-1 w-full max-h-60 overflow-y-auto rounded-lg border border-[#E9D5FF] bg-white shadow-xl shadow-[#5B21B620]/20">
              {filteredAirlines.map((airline) => (
                <button
                  key={airline}
                  onClick={() => toggleAirline(airline)}
                  className="w-full border-b border-[#F3E8FF] px-4 py-2 text-left hover:bg-[#F5F3FF] last:border-b-0"
                >
                  <div className="flex items-center">
                    <input
                      type="checkbox"
                      checked={filter.airlinePreferences.includes(airline)}
                      readOnly
                      className="mr-3 h-4 w-4 rounded border-[#E9D5FF] text-[#8B5CF6] focus:ring-[#8B5CF6]"
                    />
                    {airline}
                  </div>
                </button>
              ))}
            </div>
          )}
        </div>
        
        {filter.airlinePreferences.length > 0 && (
          <div className="flex flex-wrap gap-2">
            {filter.airlinePreferences.map((airline) => (
              <span
                key={airline}
                className="inline-flex items-center rounded-full bg-[#DDD6FE] px-3 py-1 text-sm text-[#4C1D95]"
              >
                {airline}
                <button
                  onClick={() => toggleAirline(airline)}
                  className="ml-2 text-[#7C3AED] hover:text-[#5B21B6]"
                >
                  ×
                </button>
              </span>
            ))}
          </div>
        )}
        
        <p className="mt-2 text-sm text-[#4C1D95]/70">
          {filter.airlinePreferences.length === 0 
            ? 'No specific airline preferences - we\'ll search all available carriers'
            : `Preferring ${filter.airlinePreferences.length} airline(s)`
          }
        </p>
      </div>

      {/* Maximum Stops */}
      <div className="rounded-xl border border-[#E9D5FF] bg-[#F5F3FF] p-4">
        <h3 className="mb-3 font-semibold text-[#4C1D95]">Maximum Stops</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
          {stopOptions.map((option) => (
            <button
              key={option.value}
              onClick={() => updateFilter({ maxStops: option.value as any })}
              className={`rounded-lg border-2 p-4 text-center transition-colors ${
                filter.maxStops === option.value
                  ? 'border-transparent bg-gradient-to-br from-[#8B5CF6] via-[#7C3AED] to-[#6B21A8] text-white shadow-lg shadow-[#5B21B650]'
                  : 'border-[#E9D5FF] bg-white text-[#4C1D95] hover:border-[#C4B5FD]'
              }`}
            >
              <div className="font-medium">{option.label}</div>
              <div className={`text-sm ${filter.maxStops === option.value ? 'text-white/80' : 'text-[#4C1D95]/70'}`}>
                {option.description}
              </div>
            </button>
          ))}
        </div>
      </div>

      {/* Preferred Times */}
      <div className="rounded-xl border border-[#E9D5FF] bg-[#F5F3FF] p-4">
        <h3 className="mb-3 flex items-center font-semibold text-[#4C1D95]">
          <Clock className="w-4 h-4 mr-2 text-[#7C3AED]" />
          Preferred Times
        </h3>
        
        {/* Departure Times */}
        <div className="mb-4">
          <h4 className="mb-2 text-sm font-medium text-[#4C1D95]">
            Departure Times
          </h4>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
            {timeSlots.map((slot) => (
              <button
                key={slot.value}
                onClick={() => toggleTimePreference('departure', slot.value)}
                className={`rounded-lg border-2 p-3 text-center transition-colors ${
                  filter.preferredTimes.departure.includes(slot.value as any)
                    ? 'border-transparent bg-gradient-to-br from-[#8B5CF6] via-[#7C3AED] to-[#6B21A8] text-white shadow-lg shadow-[#5B21B650]'
                    : 'border-[#E9D5FF] bg-white text-[#4C1D95] hover:border-[#C4B5FD]'
                }`}
              >
                <div className="mb-1 text-lg">{slot.icon}</div>
                <div
                  className={`text-xs font-medium ${
                    filter.preferredTimes.departure.includes(slot.value as any)
                      ? 'text-white/90'
                      : 'text-[#4C1D95]/80'
                  }`}
                >
                  {slot.label}
                </div>
              </button>
            ))}
          </div>
        </div>

        {/* Arrival Times */}
        <div>
          <h4 className="mb-2 text-sm font-medium text-[#4C1D95]">
            Arrival Times
          </h4>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
            {timeSlots.map((slot) => (
              <button
                key={slot.value}
                onClick={() => toggleTimePreference('arrival', slot.value)}
                className={`rounded-lg border-2 p-3 text-center transition-colors ${
                  filter.preferredTimes.arrival.includes(slot.value as any)
                    ? 'border-transparent bg-gradient-to-br from-[#8B5CF6] via-[#7C3AED] to-[#6B21A8] text-white shadow-lg shadow-[#5B21B650]'
                    : 'border-[#E9D5FF] bg-white text-[#4C1D95] hover:border-[#C4B5FD]'
                }`}
              >
                <div className="mb-1 text-lg">{slot.icon}</div>
                <div
                  className={`text-xs font-medium ${
                    filter.preferredTimes.arrival.includes(slot.value as any)
                      ? 'text-white/90'
                      : 'text-[#4C1D95]/80'
                  }`}
                >
                  {slot.label}
                </div>
              </button>
            ))}
          </div>
        </div>

        <div className="mt-3 flex items-start">
          <Info className="mr-2 mt-0.5 h-4 w-4 flex-shrink-0 text-[#8B5CF6]" />
          <p className="text-sm text-[#4C1D95]">
            Select your preferred departure and arrival times. We'll prioritize flights that match your preferences.
          </p>
        </div>
      </div>

      {/* Preferences Summary */}
      <div className="rounded-xl border border-[#14B8A6]/40 bg-gradient-to-r from-[#0ea5e9]/20 via-[#06B6D4]/20 to-transparent p-4 text-[#0f172a]">
        <h3 className="mb-2 font-medium text-[#0f172a]">
          Flight Preferences Summary
        </h3>
        <div className="grid grid-cols-1 gap-4 text-sm text-[#0f172a]/80 md:grid-cols-2">
          <div>
            <span className="font-medium">Cabin:</span> {filter.cabinClass.replace('-', ' ').replace(/\b\w/g, l => l.toUpperCase())}
          </div>
          <div>
            <span className="font-medium">Passengers:</span> {filter.passengers.adults + filter.passengers.children + filter.passengers.infants}
          </div>
          <div>
            <span className="font-medium">Stops:</span> {filter.maxStops.replace('-', ' ').replace(/\b\w/g, l => l.toUpperCase())}
          </div>
          <div>
            <span className="font-medium">Airlines:</span> {filter.airlinePreferences.length || 'Any'}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Step2FlightPreferences;
