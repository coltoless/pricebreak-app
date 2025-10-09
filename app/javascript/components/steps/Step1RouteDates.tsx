import React, { useState } from 'react';
import { Calendar, Plane, Info } from 'lucide-react';
import { FlightFilter, Airport, ValidationError } from '../../types/flight-filter';
import ResponsiveAirportAutocomplete from '../ResponsiveAirportAutocomplete';

interface Step1RouteDatesProps {
  filter: FlightFilter;
  updateFilter: (updates: Partial<FlightFilter>) => void;
  errors: ValidationError[];
}

const Step1RouteDates: React.FC<Step1RouteDatesProps> = ({ filter, updateFilter, errors }) => {
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

  const formatDate = (date: Date | null) => {
    if (!date) return '';
    return date.toISOString().split('T')[0];
  };

  return (
    <div className="space-y-6">
      <div className="text-center mb-6">
        <h2 className="text-2xl font-bold text-gray-900 mb-2">Route & Dates</h2>
        <p className="text-gray-600">Set your travel route and preferred dates</p>
      </div>

      {/* Trip Type */}
      <div className="bg-gray-50 p-4 rounded-lg">
        <h3 className="font-semibold text-gray-900 mb-3 flex items-center">
          <Plane className="w-4 h-4 mr-2" />
          Trip Type
        </h3>
        <div className="grid grid-cols-3 gap-3">
          {(['one-way', 'round-trip', 'multi-city'] as const).map((type) => (
            <button
              key={type}
              onClick={() => updateFilter({ tripType: type })}
              className={`p-3 rounded-lg border-2 transition-colors ${
                filter.tripType === type
                  ? 'border-blue-500 bg-blue-50 text-blue-700'
                  : 'border-gray-300 bg-white text-gray-700 hover:border-gray-400'
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

      {/* Date Selection */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Departure Date */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Departure Date
          </label>
          <div className="relative">
            <input
              type="date"
              value={formatDate(filter.departureDate)}
              onChange={(e) => {
                const date = e.target.value ? new Date(e.target.value) : null;
                updateFilter({ departureDate: date });
              }}
              min={new Date().toISOString().split('T')[0]}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
            <Calendar className="absolute right-3 top-3.5 h-5 w-5 text-gray-400" />
          </div>
          
          {getError('departureDate') && (
            <p className="mt-1 text-sm text-red-600">{getError('departureDate')}</p>
          )}
        </div>

        {/* Return Date */}
        {filter.tripType === 'round-trip' && (
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Return Date
            </label>
            <div className="relative">
              <input
                type="date"
                value={formatDate(filter.returnDate)}
                onChange={(e) => {
                  const date = e.target.value ? new Date(e.target.value) : null;
                  updateFilter({ returnDate: date });
                }}
                min={filter.departureDate ? filter.departureDate.toISOString().split('T')[0] : new Date().toISOString().split('T')[0]}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              />
              <Calendar className="absolute right-3 top-3.5 h-5 w-5 text-gray-400" />
            </div>
            
            {getError('returnDate') && (
              <p className="mt-1 text-sm text-red-600">{getError('returnDate')}</p>
            )}
          </div>
        )}
      </div>

      {/* Flexible Dates */}
      <div className="bg-blue-50 p-4 rounded-lg">
        <div className="flex items-center justify-between">
          <div className="flex items-center">
            <input
              type="checkbox"
              id="flexibleDates"
              checked={filter.flexibleDates}
              onChange={(e) => updateFilter({ flexibleDates: e.target.checked })}
              className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
            />
            <label htmlFor="flexibleDates" className="ml-2 text-sm font-medium text-gray-900">
              Flexible Dates
            </label>
          </div>
          
          {filter.flexibleDates && (
            <div className="flex items-center space-x-2">
              <span className="text-sm text-gray-600">±</span>
              <select
                value={filter.dateFlexibility}
                onChange={(e) => updateFilter({ dateFlexibility: parseInt(e.target.value) })}
                className="px-3 py-1 border border-gray-300 rounded-md text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
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
          <Info className="w-4 h-4 text-blue-500 mr-2 mt-0.5 flex-shrink-0" />
          <p className="text-sm text-blue-700">
            {filter.flexibleDates 
              ? `We'll search for flights within ±${filter.dateFlexibility} days of your preferred dates to find better prices.`
              : 'Enable flexible dates to search for flights within a few days of your preferred dates, often resulting in better prices.'
            }
          </p>
        </div>
      </div>

      {/* Route Summary */}
      {filter.origin && filter.destination && (
        <div className="bg-green-50 p-4 rounded-lg border border-green-200">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="w-3 h-3 bg-green-500 rounded-full"></div>
              <span className="font-medium text-green-800">
                Route: {filter.origin.iata_code} → {filter.destination.iata_code}
              </span>
            </div>
            <span className="text-sm text-green-600">
              {filter.tripType.replace('-', ' ').replace(/\b\w/g, l => l.toUpperCase())}
            </span>
          </div>
          
          {filter.departureDate && (
            <div className="mt-2 text-sm text-green-700">
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
