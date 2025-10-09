// Enhanced Flight Filter Integration for Local Rails App
import React from 'react';
import { createRoot } from 'react-dom/client';
import FlightPriceFilter from '../components/FlightPriceFilter';
import ResponsiveAirportAutocomplete from '../components/ResponsiveAirportAutocomplete';
import { AirportService } from '../lib/firebase';

// Enhanced Airport Autocomplete Test Component
function AirportAutocompleteTest() {
  const [originSearch, setOriginSearch] = React.useState('');
  const [destinationSearch, setDestinationSearch] = React.useState('');
  const [originAirport, setOriginAirport] = React.useState(null);
  const [destinationAirport, setDestinationAirport] = React.useState(null);
  const [searchResults, setSearchResults] = React.useState([]);
  const [isLoading, setIsLoading] = React.useState(false);

  const handleOriginSelect = (airport) => {
    setOriginAirport(airport);
    if (airport) {
      setOriginSearch(`${airport.iata_code} - ${airport.city}`);
    }
  };

  const handleDestinationSelect = (airport) => {
    setDestinationAirport(airport);
    if (airport) {
      setDestinationSearch(`${airport.iata_code} - ${airport.city}`);
    }
  };

  const testSearch = async (query) => {
    if (!query || query.length < 2) return;
    
    setIsLoading(true);
    try {
      const results = await AirportService.searchAirports(query);
      setSearchResults(results.slice(0, 5)); // Show top 5 results
    } catch (error) {
      console.error('Search error:', error);
      setSearchResults([]);
    } finally {
      setIsLoading(false);
    }
  };

  const clearResults = () => {
    setSearchResults([]);
    setOriginSearch('');
    setDestinationSearch('');
    setOriginAirport(null);
    setDestinationAirport(null);
  };

  return (
    <div className="space-y-6">
      {/* Search Interface */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Origin Airport
          </label>
          <ResponsiveAirportAutocomplete
            value={originSearch}
            onChange={setOriginSearch}
            onSelect={handleOriginSelect}
            placeholder="Search origin airports..."
            selectedAirport={originAirport}
            showPopularAirports={true}
            size="lg"
            variant="outlined"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Destination Airport
          </label>
          <ResponsiveAirportAutocomplete
            value={destinationSearch}
            onChange={setDestinationSearch}
            onSelect={handleDestinationSelect}
            placeholder="Search destination airports..."
            selectedAirport={destinationAirport}
            showPopularAirports={true}
            size="lg"
            variant="outlined"
          />
        </div>
      </div>

      {/* Quick Search Test */}
      <div className="bg-gray-50 rounded-lg p-4">
        <h4 className="text-sm font-medium text-gray-900 mb-3">Quick Search Test</h4>
        <div className="flex flex-wrap gap-2">
          {['JFK', 'London', 'Tokyo', 'Dubai', 'Sydney', 'Brazil', 'Germany'].map((term) => (
            <button
              key={term}
              onClick={() => testSearch(term)}
              className="px-3 py-1 text-xs bg-blue-100 text-blue-700 rounded-full hover:bg-blue-200 transition-colors"
            >
              {term}
            </button>
          ))}
        </div>
        
        {isLoading && (
          <div className="mt-3 text-center">
            <div className="inline-block h-4 w-4 border-2 border-blue-500 border-t-transparent rounded-full animate-spin"></div>
            <span className="ml-2 text-sm text-gray-600">Searching...</span>
          </div>
        )}

        {searchResults.length > 0 && (
          <div className="mt-3">
            <h5 className="text-xs font-medium text-gray-700 mb-2">Search Results:</h5>
            <div className="space-y-1">
              {searchResults.map((airport, index) => (
                <div key={index} className="text-xs bg-white p-2 rounded border">
                  <span className="font-semibold">{airport.iata_code}</span> - {airport.city}, {airport.country}
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Selected Airports Display */}
      {(originAirport || destinationAirport) && (
        <div className="bg-green-50 rounded-lg p-4">
          <h4 className="text-sm font-medium text-green-900 mb-3">Selected Airports</h4>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {originAirport && (
              <div className="bg-white p-3 rounded border">
                <div className="text-sm font-semibold text-gray-900">Origin</div>
                <div className="text-xs text-gray-600">
                  {originAirport.iata_code} - {originAirport.name}
                </div>
                <div className="text-xs text-gray-500">
                  {originAirport.city}, {originAirport.country}
                </div>
              </div>
            )}
            {destinationAirport && (
              <div className="bg-white p-3 rounded border">
                <div className="text-sm font-semibold text-gray-900">Destination</div>
                <div className="text-xs text-gray-600">
                  {destinationAirport.iata_code} - {destinationAirport.name}
                </div>
                <div className="text-xs text-gray-500">
                  {destinationAirport.city}, {destinationAirport.country}
                </div>
              </div>
            )}
          </div>
          <button
            onClick={clearResults}
            className="mt-3 px-3 py-1 text-xs bg-red-100 text-red-700 rounded hover:bg-red-200 transition-colors"
          >
            Clear All
          </button>
        </div>
      )}

      {/* Database Stats */}
      <div className="bg-blue-50 rounded-lg p-4">
        <h4 className="text-sm font-medium text-blue-900 mb-3">Database Statistics</h4>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-center">
          <div>
            <div className="text-lg font-bold text-blue-600">6,218</div>
            <div className="text-xs text-blue-700">Total Airports</div>
          </div>
          <div>
            <div className="text-lg font-bold text-blue-600">195+</div>
            <div className="text-xs text-blue-700">Countries</div>
          </div>
          <div>
            <div className="text-lg font-bold text-blue-600">&lt;50ms</div>
            <div className="text-xs text-blue-700">Search Speed</div>
          </div>
          <div>
            <div className="text-lg font-bold text-blue-600">100%</div>
            <div className="text-xs text-blue-700">Coverage</div>
          </div>
        </div>
      </div>
    </div>
  );
}

// Enhanced Flight Filter Demo Component
function EnhancedFlightFilterDemo() {
  const [currentStep, setCurrentStep] = React.useState(1);
  const [filter, setFilter] = React.useState({
    origin: null,
    destination: null,
    tripType: 'round-trip',
    departureDate: null,
    returnDate: null,
    flexibleDates: false,
    dateFlexibility: 3,
    cabinClass: 'economy',
    passengers: { adults: 1, children: 0, infants: 0 },
    airlinePreferences: [],
    maxStops: 'nonstop',
    preferredTimes: { departure: [], arrival: [] },
    targetPrice: 0,
    currency: 'USD',
    instantPriceBreakAlerts: {
      enabled: false,
      type: 'exact-match',
      flexibilityOptions: {
        airline: false,
        stops: false,
        times: false,
        dates: false
      }
    },
    priceDropPercentage: 20,
    budgetRange: { min: 0, max: 1000 },
    priceBreakConfidence: 'medium',
    monitorFrequency: 'daily',
    alertUrgency: 'moderate',
    instantAlertPriority: 'high',
    alertDetailLevel: 'exact-matches-only',
    notificationMethods: {
      email: true,
      sms: false,
      push: true,
      browser: true
    },
    filterName: '',
    description: '',
    createdAt: new Date(),
    isActive: true
  });

  const [originSearch, setOriginSearch] = React.useState('');
  const [destinationSearch, setDestinationSearch] = React.useState('');

  const updateFilter = (updates) => {
    setFilter(prev => ({ ...prev, ...updates }));
  };

  const handleOriginSelect = (airport) => {
    updateFilter({ origin: airport });
  };

  const handleDestinationSelect = (airport) => {
    updateFilter({ destination: airport });
  };

  const formatDate = (date) => {
    if (!date) return '';
    return date.toISOString().split('T')[0];
  };

  const getMinDate = () => {
    return new Date().toISOString().split('T')[0];
  };

  const getMaxDate = () => {
    const maxDate = new Date();
    maxDate.setFullYear(maxDate.getFullYear() + 1);
    return maxDate.toISOString().split('T')[0];
  };

  return (
    <div className="max-w-4xl mx-auto">
      {/* Step Indicator */}
      <div className="mb-8">
        <div className="flex items-center justify-center space-x-4">
          {[1, 2, 3, 4].map((step) => (
            <div key={step} className="flex items-center">
              <div className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium ${
                step === currentStep 
                  ? 'bg-blue-600 text-white' 
                  : step < currentStep 
                    ? 'bg-green-500 text-white' 
                    : 'bg-gray-200 text-gray-600'
              }`}>
                {step < currentStep ? '✓' : step}
              </div>
              {step < 4 && (
                <div className={`w-16 h-1 mx-2 ${
                  step < currentStep ? 'bg-green-500' : 'bg-gray-200'
                }`}></div>
              )}
            </div>
          ))}
        </div>
        <div className="text-center mt-4">
          <h2 className="text-xl font-semibold text-gray-900">
            {currentStep === 1 && 'Route & Dates'}
            {currentStep === 2 && 'Flight Preferences'}
            {currentStep === 3 && 'Price Settings'}
            {currentStep === 4 && 'Alert Preferences'}
          </h2>
        </div>
      </div>

      {/* Step Content */}
      <div className="bg-white rounded-lg shadow-lg p-8">
        {currentStep === 1 && (
          <div className="space-y-6">
            {/* Trip Type */}
            <div>
              <h3 className="text-lg font-semibold text-gray-900 mb-4">Trip Type</h3>
              <div className="grid grid-cols-3 gap-3">
                {(['one-way', 'round-trip', 'multi-city']).map((type) => (
                  <button
                    key={type}
                    onClick={() => updateFilter({ tripType: type })}
                    className={`p-4 rounded-lg border-2 transition-colors ${
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

            {/* Route Selection with Enhanced Autocomplete */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <ResponsiveAirportAutocomplete
                value={originSearch}
                onChange={setOriginSearch}
                onSelect={handleOriginSelect}
                placeholder="Search origin airports..."
                label="Origin Airport"
                selectedAirport={filter.origin}
                showPopularAirports={true}
                size="lg"
                variant="outlined"
              />

              <ResponsiveAirportAutocomplete
                value={destinationSearch}
                onChange={setDestinationSearch}
                onSelect={handleDestinationSelect}
                placeholder="Search destination airports..."
                label="Destination Airport"
                selectedAirport={filter.destination}
                showPopularAirports={true}
                size="lg"
                variant="outlined"
              />
            </div>

            {/* Date Selection */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Departure Date
                </label>
                <input
                  type="date"
                  value={formatDate(filter.departureDate)}
                  onChange={(e) => updateFilter({ departureDate: e.target.value ? new Date(e.target.value) : null })}
                  min={getMinDate()}
                  max={getMaxDate()}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                />
              </div>

              {filter.tripType === 'round-trip' && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Return Date
                  </label>
                  <input
                    type="date"
                    value={formatDate(filter.returnDate)}
                    onChange={(e) => updateFilter({ returnDate: e.target.value ? new Date(e.target.value) : null })}
                    min={filter.departureDate ? formatDate(filter.departureDate) : getMinDate()}
                    max={getMaxDate()}
                    className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>
              )}
            </div>

            {/* Flexible Dates */}
            <div className="flex items-center space-x-3">
              <input
                type="checkbox"
                id="flexibleDates"
                checked={filter.flexibleDates}
                onChange={(e) => updateFilter({ flexibleDates: e.target.checked })}
                className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
              />
              <label htmlFor="flexibleDates" className="text-sm text-gray-700">
                Flexible dates (±{filter.dateFlexibility} days)
              </label>
            </div>
          </div>
        )}

        {currentStep === 2 && (
          <div className="space-y-6">
            <h3 className="text-lg font-semibold text-gray-900">Flight Preferences</h3>
            
            {/* Cabin Class */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Cabin Class</label>
              <div className="grid grid-cols-4 gap-3">
                {(['economy', 'premium-economy', 'business', 'first']).map((cabin) => (
                  <button
                    key={cabin}
                    onClick={() => updateFilter({ cabinClass: cabin })}
                    className={`p-3 rounded-lg border-2 transition-colors ${
                      filter.cabinClass === cabin
                        ? 'border-blue-500 bg-blue-50 text-blue-700'
                        : 'border-gray-300 bg-white text-gray-700 hover:border-gray-400'
                    }`}
                  >
                    <div className="text-sm font-medium capitalize">{cabin.replace('-', ' ')}</div>
                  </button>
                ))}
              </div>
            </div>

            {/* Passengers */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Passengers</label>
              <div className="grid grid-cols-3 gap-4">
                {(['adults', 'children', 'infants']).map((type) => (
                  <div key={type} className="flex items-center justify-between">
                    <span className="text-sm text-gray-700 capitalize">{type}</span>
                    <div className="flex items-center space-x-2">
                      <button
                        onClick={() => updateFilter({
                          passengers: {
                            ...filter.passengers,
                            [type]: Math.max(0, filter.passengers[type] - 1)
                          }
                        })}
                        className="w-8 h-8 rounded-full border border-gray-300 flex items-center justify-center hover:bg-gray-50"
                      >
                        -
                      </button>
                      <span className="w-8 text-center">{filter.passengers[type]}</span>
                      <button
                        onClick={() => updateFilter({
                          passengers: {
                            ...filter.passengers,
                            [type]: filter.passengers[type] + 1
                          }
                        })}
                        className="w-8 h-8 rounded-full border border-gray-300 flex items-center justify-center hover:bg-gray-50"
                      >
                        +
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Max Stops */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Maximum Stops</label>
              <div className="grid grid-cols-3 gap-3">
                {(['nonstop', '1-stop', '2+']).map((stops) => (
                  <button
                    key={stops}
                    onClick={() => updateFilter({ maxStops: stops })}
                    className={`p-3 rounded-lg border-2 transition-colors ${
                      filter.maxStops === stops
                        ? 'border-blue-500 bg-blue-50 text-blue-700'
                        : 'border-gray-300 bg-white text-gray-700 hover:border-gray-400'
                    }`}
                  >
                    <div className="text-sm font-medium">{stops}</div>
                  </button>
                ))}
              </div>
            </div>
          </div>
        )}

        {currentStep === 3 && (
          <div className="space-y-6">
            <h3 className="text-lg font-semibold text-gray-900">Price Settings</h3>
            
            {/* Target Price */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Target Price (USD)
              </label>
              <input
                type="number"
                value={filter.targetPrice}
                onChange={(e) => updateFilter({ targetPrice: parseInt(e.target.value) || 0 })}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                placeholder="Enter your target price"
              />
            </div>

            {/* Budget Range */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Min Budget (USD)
                </label>
                <input
                  type="number"
                  value={filter.budgetRange.min}
                  onChange={(e) => updateFilter({
                    budgetRange: {
                      ...filter.budgetRange,
                      min: parseInt(e.target.value) || 0
                    }
                  })}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Max Budget (USD)
                </label>
                <input
                  type="number"
                  value={filter.budgetRange.max}
                  onChange={(e) => updateFilter({
                    budgetRange: {
                      ...filter.budgetRange,
                      max: parseInt(e.target.value) || 1000
                    }
                  })}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                />
              </div>
            </div>

            {/* Price Drop Percentage */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Price Drop Alert (%)
              </label>
              <input
                type="range"
                min="5"
                max="50"
                value={filter.priceDropPercentage}
                onChange={(e) => updateFilter({ priceDropPercentage: parseInt(e.target.value) })}
                className="w-full"
              />
              <div className="text-center text-sm text-gray-600 mt-1">
                Alert when price drops by {filter.priceDropPercentage}%
              </div>
            </div>
          </div>
        )}

        {currentStep === 4 && (
          <div className="space-y-6">
            <h3 className="text-lg font-semibold text-gray-900">Alert Preferences</h3>
            
            {/* Monitor Frequency */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Monitor Frequency</label>
              <div className="grid grid-cols-4 gap-3">
                {(['real-time', 'hourly', 'daily', 'weekly']).map((frequency) => (
                  <button
                    key={frequency}
                    onClick={() => updateFilter({ monitorFrequency: frequency })}
                    className={`p-3 rounded-lg border-2 transition-colors ${
                      filter.monitorFrequency === frequency
                        ? 'border-blue-500 bg-blue-50 text-blue-700'
                        : 'border-gray-300 bg-white text-gray-700 hover:border-gray-400'
                    }`}
                  >
                    <div className="text-sm font-medium capitalize">{frequency}</div>
                  </button>
                ))}
              </div>
            </div>

            {/* Notification Methods */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Notification Methods</label>
              <div className="space-y-3">
                {(['email', 'sms', 'push', 'browser']).map((method) => (
                  <div key={method} className="flex items-center space-x-3">
                    <input
                      type="checkbox"
                      id={method}
                      checked={filter.notificationMethods[method]}
                      onChange={(e) => updateFilter({
                        notificationMethods: {
                          ...filter.notificationMethods,
                          [method]: e.target.checked
                        }
                      })}
                      className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                    />
                    <label htmlFor={method} className="text-sm text-gray-700 capitalize">
                      {method === 'push' ? 'Push Notifications' : method}
                    </label>
                  </div>
                ))}
              </div>
            </div>

            {/* Filter Name */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Filter Name
              </label>
              <input
                type="text"
                value={filter.filterName}
                onChange={(e) => updateFilter({ filterName: e.target.value })}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                placeholder="Give your filter a name"
              />
            </div>
          </div>
        )}

        {/* Navigation */}
        <div className="flex justify-between mt-8 pt-6 border-t border-gray-200">
          <button
            onClick={() => setCurrentStep(Math.max(1, currentStep - 1))}
            disabled={currentStep === 1}
            className="px-6 py-3 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Previous
          </button>
          
          {currentStep < 4 ? (
            <button
              onClick={() => setCurrentStep(Math.min(4, currentStep + 1))}
              className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            >
              Next
            </button>
          ) : (
            <button
              onClick={() => {
                alert('Filter saved! Check the console for the complete filter data.');
                console.log('Complete Filter:', filter);
              }}
              className="px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700"
            >
              Save Filter
            </button>
          )}
        </div>
      </div>

      {/* Filter Summary */}
      <div className="mt-8 bg-gray-50 rounded-lg p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Current Filter Summary</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
          <div>
            <span className="font-medium">Origin:</span> {filter.origin ? `${filter.origin.iata_code} - ${filter.origin.city}` : 'Not selected'}
          </div>
          <div>
            <span className="font-medium">Destination:</span> {filter.destination ? `${filter.destination.iata_code} - ${filter.destination.city}` : 'Not selected'}
          </div>
          <div>
            <span className="font-medium">Trip Type:</span> {filter.tripType}
          </div>
          <div>
            <span className="font-medium">Cabin Class:</span> {filter.cabinClass}
          </div>
          <div>
            <span className="font-medium">Passengers:</span> {filter.passengers.adults + filter.passengers.children + filter.passengers.infants}
          </div>
          <div>
            <span className="font-medium">Target Price:</span> ${filter.targetPrice}
          </div>
        </div>
      </div>
    </div>
  );
}

// Initialize components when DOM is ready
document.addEventListener('DOMContentLoaded', function() {
  // Mount Enhanced Flight Filter Demo
  const flightFilterDemo = document.getElementById('flight-filter-demo');
  if (flightFilterDemo) {
    const root = createRoot(flightFilterDemo);
    root.render(<EnhancedFlightFilterDemo />);
  }

  // Mount Airport Autocomplete Test
  const airportTest = document.getElementById('airport-autocomplete-test');
  if (airportTest) {
    const root = createRoot(airportTest);
    root.render(<AirportAutocompleteTest />);
  }
});


