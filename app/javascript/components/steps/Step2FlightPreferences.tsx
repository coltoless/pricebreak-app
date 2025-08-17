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
    <div className="space-y-6">
      <div className="text-center mb-6">
        <h2 className="text-2xl font-bold text-gray-900 mb-2">Flight Preferences</h2>
        <p className="text-gray-600">Customize your flight experience and preferences</p>
      </div>

      {/* Cabin Class */}
      <div className="bg-gray-50 p-4 rounded-lg">
        <h3 className="font-semibold text-gray-900 mb-3 flex items-center">
          <Plane className="w-4 h-4 mr-2" />
          Cabin Class
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          {cabinClasses.map((cabin) => (
            <button
              key={cabin.value}
              onClick={() => updateFilter({ cabinClass: cabin.value as any })}
              className={`p-4 rounded-lg border-2 transition-colors text-left ${
                filter.cabinClass === cabin.value
                  ? 'border-blue-500 bg-blue-50 text-blue-700'
                  : 'border-gray-300 bg-white text-gray-700 hover:border-gray-400'
              }`}
            >
              <div className="font-medium">{cabin.label}</div>
              <div className="text-sm text-gray-600">{cabin.description}</div>
              <div className="text-xs font-medium text-blue-600">{cabin.price}</div>
            </button>
          ))}
        </div>
      </div>

      {/* Passengers */}
      <div className="bg-gray-50 p-4 rounded-lg">
        <h3 className="font-semibold text-gray-900 mb-3 flex items-center">
          <Users className="w-4 h-4 mr-2" />
          Passengers
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {(['adults', 'children', 'infants'] as const).map((type) => (
            <div key={type} className="text-center">
              <label className="block text-sm font-medium text-gray-700 mb-2 capitalize">
                {type}
              </label>
              <div className="flex items-center justify-center space-x-2">
                <button
                  onClick={() => updatePassengers(type, filter.passengers[type] - 1)}
                  disabled={filter.passengers[type] === 0}
                  className="w-8 h-8 rounded-full bg-gray-200 text-gray-600 hover:bg-gray-300 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center"
                >
                  -
                </button>
                <span className="w-12 text-center font-medium text-lg">
                  {filter.passengers[type]}
                </span>
                <button
                  onClick={() => updatePassengers(type, filter.passengers[type] + 1)}
                  className="w-8 h-8 rounded-full bg-blue-500 text-white hover:bg-blue-600 flex items-center justify-center"
                >
                  +
                </button>
              </div>
              {type === 'infants' && (
                <p className="text-xs text-gray-500 mt-1">
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
      <div className="bg-gray-50 p-4 rounded-lg">
        <h3 className="font-semibold text-gray-900 mb-3">Airline Preferences</h3>
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
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          />
          
          {showAirlineDropdown && (
            <div className="absolute z-10 w-full mt-1 bg-white border border-gray-300 rounded-lg shadow-lg max-h-60 overflow-y-auto">
              {filteredAirlines.map((airline) => (
                <button
                  key={airline}
                  onClick={() => toggleAirline(airline)}
                  className="w-full text-left px-4 py-2 hover:bg-gray-50 border-b border-gray-100 last:border-b-0"
                >
                  <div className="flex items-center">
                    <input
                      type="checkbox"
                      checked={filter.airlinePreferences.includes(airline)}
                      readOnly
                      className="mr-3 h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
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
                className="inline-flex items-center px-3 py-1 rounded-full text-sm bg-blue-100 text-blue-800"
              >
                {airline}
                <button
                  onClick={() => toggleAirline(airline)}
                  className="ml-2 text-blue-600 hover:text-blue-800"
                >
                  ×
                </button>
              </span>
            ))}
          </div>
        )}
        
        <p className="text-sm text-gray-600 mt-2">
          {filter.airlinePreferences.length === 0 
            ? 'No specific airline preferences - we\'ll search all available carriers'
            : `Preferring ${filter.airlinePreferences.length} airline(s)`
          }
        </p>
      </div>

      {/* Maximum Stops */}
      <div className="bg-gray-50 p-4 rounded-lg">
        <h3 className="font-semibold text-gray-900 mb-3">Maximum Stops</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
          {stopOptions.map((option) => (
            <button
              key={option.value}
              onClick={() => updateFilter({ maxStops: option.value as any })}
              className={`p-4 rounded-lg border-2 transition-colors text-center ${
                filter.maxStops === option.value
                  ? 'border-blue-500 bg-blue-50 text-blue-700'
                  : 'border-gray-300 bg-white text-gray-700 hover:border-gray-400'
              }`}
            >
              <div className="font-medium">{option.label}</div>
              <div className="text-sm text-gray-600">{option.description}</div>
            </button>
          ))}
        </div>
      </div>

      {/* Preferred Times */}
      <div className="bg-gray-50 p-4 rounded-lg">
        <h3 className="font-semibold text-gray-900 mb-3 flex items-center">
          <Clock className="w-4 h-4 mr-2" />
          Preferred Times
        </h3>
        
        {/* Departure Times */}
        <div className="mb-4">
          <h4 className="text-sm font-medium text-gray-700 mb-2">Departure Times</h4>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
            {timeSlots.map((slot) => (
              <button
                key={slot.value}
                onClick={() => toggleTimePreference('departure', slot.value)}
                className={`p-3 rounded-lg border-2 transition-colors text-center ${
                  filter.preferredTimes.departure.includes(slot.value as any)
                    ? 'border-blue-500 bg-blue-50 text-blue-700'
                    : 'border-gray-300 bg-white text-gray-700 hover:border-gray-400'
                }`}
              >
                <div className="text-lg mb-1">{slot.icon}</div>
                <div className="text-xs font-medium">{slot.label}</div>
              </button>
            ))}
          </div>
        </div>

        {/* Arrival Times */}
        <div>
          <h4 className="text-sm font-medium text-gray-700 mb-2">Arrival Times</h4>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
            {timeSlots.map((slot) => (
              <button
                key={slot.value}
                onClick={() => toggleTimePreference('arrival', slot.value)}
                className={`p-3 rounded-lg border-2 transition-colors text-center ${
                  filter.preferredTimes.arrival.includes(slot.value as any)
                    ? 'border-blue-500 bg-blue-50 text-blue-700'
                    : 'border-gray-300 bg-white text-gray-700 hover:border-gray-400'
                }`}
              >
                <div className="text-lg mb-1">{slot.icon}</div>
                <div className="text-xs font-medium">{slot.label}</div>
              </button>
            ))}
          </div>
        </div>

        <div className="mt-3 flex items-start">
          <Info className="w-4 h-4 text-blue-500 mr-2 mt-0.5 flex-shrink-0" />
          <p className="text-sm text-blue-700">
            Select your preferred departure and arrival times. We'll prioritize flights that match your preferences.
          </p>
        </div>
      </div>

      {/* Preferences Summary */}
      <div className="bg-green-50 p-4 rounded-lg border border-green-200">
        <h3 className="font-medium text-green-800 mb-2">Flight Preferences Summary</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm text-green-700">
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
