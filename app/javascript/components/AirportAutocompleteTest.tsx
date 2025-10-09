import React, { useState } from 'react';
import { createRoot } from 'react-dom/client';
import AirportAutocomplete from './AirportAutocomplete';
import { Airport } from '../types/flight-filter';

const AirportAutocompleteTest: React.FC = () => {
  const [originSearch, setOriginSearch] = useState('');
  const [destinationSearch, setDestinationSearch] = useState('');
  const [selectedOrigin, setSelectedOrigin] = useState<Airport | null>(null);
  const [selectedDestination, setSelectedDestination] = useState<Airport | null>(null);

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Origin Airport */}
        <div>
          <AirportAutocomplete
            value={originSearch}
            onChange={setOriginSearch}
            onSelect={setSelectedOrigin}
            placeholder="Search origin airports..."
            label="Origin Airport"
            selectedAirport={selectedOrigin}
          />
          
          {selectedOrigin && (
            <div className="mt-3 p-3 bg-green-50 rounded-lg border border-green-200">
              <h4 className="font-medium text-green-900 mb-1">Selected Origin:</h4>
              <p className="text-sm text-green-800">
                <strong>{selectedOrigin.iata_code}</strong> - {selectedOrigin.name}
              </p>
              <p className="text-xs text-green-700">
                {selectedOrigin.city}, {selectedOrigin.country}
              </p>
            </div>
          )}
        </div>

        {/* Destination Airport */}
        <div>
          <AirportAutocomplete
            value={destinationSearch}
            onChange={setDestinationSearch}
            onSelect={setSelectedDestination}
            placeholder="Search destination airports..."
            label="Destination Airport"
            selectedAirport={selectedDestination}
          />
          
          {selectedDestination && (
            <div className="mt-3 p-3 bg-green-50 rounded-lg border border-green-200">
              <h4 className="font-medium text-green-900 mb-1">Selected Destination:</h4>
              <p className="text-sm text-green-800">
                <strong>{selectedDestination.iata_code}</strong> - {selectedDestination.name}
              </p>
              <p className="text-xs text-green-700">
                {selectedDestination.city}, {selectedDestination.country}
              </p>
            </div>
          )}
        </div>
      </div>

      {/* Route Summary */}
      {selectedOrigin && selectedDestination && (
        <div className="p-4 bg-blue-50 rounded-lg border border-blue-200">
          <h4 className="font-medium text-blue-900 mb-2">Route Summary:</h4>
          <p className="text-blue-800">
            <strong>{selectedOrigin.iata_code}</strong> → <strong>{selectedDestination.iata_code}</strong>
          </p>
          <p className="text-sm text-blue-700 mt-1">
            {selectedOrigin.city} → {selectedDestination.city}
          </p>
        </div>
      )}

      {/* Test Results */}
      <div className="space-y-4">
        <h3 className="font-semibold text-gray-900">Test Results:</h3>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="p-4 border rounded-lg">
            <h4 className="font-medium text-gray-900 mb-2">Origin Selection</h4>
            <pre className="text-xs text-gray-600 bg-gray-50 p-2 rounded overflow-auto">
              {JSON.stringify(selectedOrigin, null, 2)}
            </pre>
          </div>
          
          <div className="p-4 border rounded-lg">
            <h4 className="font-medium text-gray-900 mb-2">Destination Selection</h4>
            <pre className="text-xs text-gray-600 bg-gray-50 p-2 rounded overflow-auto">
              {JSON.stringify(selectedDestination, null, 2)}
            </pre>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AirportAutocompleteTest;
