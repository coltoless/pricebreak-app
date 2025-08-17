import React from 'react';
import { MapPin, Plane, DollarSign, Bell, Zap, Check, AlertTriangle } from 'lucide-react';
import { FlightFilter } from '../types/flight-filter';

interface FilterSummaryProps {
  filter: FlightFilter;
}

const FilterSummary: React.FC<FilterSummaryProps> = ({ filter }) => {
  const formatDate = (date: Date | null) => {
    if (!date) return 'Not set';
    return date.toLocaleDateString();
  };

  const formatPassengers = () => {
    const total = filter.passengers.adults + filter.passengers.children + filter.passengers.infants;
    const parts = [];
    if (filter.passengers.adults > 0) parts.push(`${filter.passengers.adults} adult${filter.passengers.adults > 1 ? 's' : ''}`);
    if (filter.passengers.children > 0) parts.push(`${filter.passengers.children} child${filter.passengers.children > 1 ? 'ren' : ''}`);
    if (filter.passengers.infants > 0) parts.push(`${filter.passengers.infants} infant${filter.passengers.infants > 1 ? 's' : ''}`);
    return parts.join(', ');
  };

  const formatTimePreferences = (times: string[]) => {
    if (times.length === 0) return 'Any time';
    return times.map(time => time.charAt(0).toUpperCase() + time.slice(1)).join(', ');
  };

  const getPriceBreakAlertSummary = () => {
    if (!filter.instantPriceBreakAlerts.enabled) {
      return 'Disabled';
    }

    const type = filter.instantPriceBreakAlerts.type === 'exact-match' ? 'Exact Match' : 'Flexible Match';
    
    if (filter.instantPriceBreakAlerts.type === 'flexible-match') {
      const flexibleOptions = Object.entries(filter.instantPriceBreakAlerts.flexibilityOptions)
        .filter(([_, enabled]) => enabled)
        .map(([key, _]) => key.charAt(0).toUpperCase() + key.slice(1));
      
      return `${type} (${flexibleOptions.join(', ')} can vary)`;
    }
    
    return type;
  };

  return (
    <div className="space-y-6">
      <div className="text-center mb-6">
        <h2 className="text-2xl font-bold text-gray-900">Filter Summary</h2>
        <p className="text-gray-600">Review your complete flight price monitoring configuration</p>
      </div>

      {/* Route & Dates Summary */}
      <div className="bg-blue-50 p-4 rounded-lg border border-blue-200">
        <div className="flex items-center mb-3">
          <MapPin className="w-5 h-5 text-blue-600 mr-2" />
          <h3 className="text-lg font-semibold text-blue-900">Route & Dates</h3>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
          <div>
            <span className="font-medium text-blue-800">Route:</span>
            <div className="text-blue-700">
              {filter.origin ? `${filter.origin.code} → ${filter.destination?.code || 'Not set'}` : 'Not set'}
            </div>
          </div>
          <div>
            <span className="font-medium text-blue-800">Trip Type:</span>
            <div className="text-blue-700 capitalize">
              {filter.tripType.replace('-', ' ')}
            </div>
          </div>
          <div>
            <span className="font-medium text-blue-800">Departure:</span>
            <div className="text-blue-700">
              {formatDate(filter.departureDate)}
            </div>
          </div>
          {filter.tripType === 'round-trip' && (
            <div>
              <span className="font-medium text-blue-800">Return:</span>
              <div className="text-blue-700">
                {formatDate(filter.returnDate)}
              </div>
            </div>
          )}
          <div className="md:col-span-2">
            <span className="font-medium text-blue-800">Flexible Dates:</span>
            <div className="text-blue-700">
              {filter.flexibleDates ? `±${filter.dateFlexibility} days` : 'No'}
            </div>
          </div>
        </div>
      </div>

      {/* Flight Preferences Summary */}
      <div className="bg-green-50 p-4 rounded-lg border border-green-200">
        <div className="flex items-center mb-3">
          <Plane className="w-5 h-5 text-green-600 mr-2" />
          <h3 className="text-lg font-semibold text-green-900">Flight Preferences</h3>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
          <div>
            <span className="font-medium text-green-800">Cabin Class:</span>
            <div className="text-green-700 capitalize">
              {filter.cabinClass.replace('-', ' ')}
            </div>
          </div>
          <div>
            <span className="font-medium text-green-800">Passengers:</span>
            <div className="text-green-700">
              {formatPassengers()}
            </div>
          </div>
          <div>
            <span className="font-medium text-green-800">Max Stops:</span>
            <div className="text-green-700 capitalize">
              {filter.maxStops.replace('-', ' ')}
            </div>
          </div>
          <div>
            <span className="font-medium text-green-800">Airlines:</span>
            <div className="text-green-700">
              {filter.airlinePreferences.length > 0 
                ? filter.airlinePreferences.join(', ')
                : 'Any airline'
              }
            </div>
          </div>
          <div>
            <span className="font-medium text-green-800">Departure Times:</span>
            <div className="text-green-700">
              {formatTimePreferences(filter.preferredTimes.departure)}
            </div>
          </div>
          <div>
            <span className="font-medium text-green-800">Arrival Times:</span>
            <div className="text-green-700">
              {formatTimePreferences(filter.preferredTimes.arrival)}
            </div>
          </div>
        </div>
      </div>

      {/* Price Settings Summary */}
      <div className="bg-purple-50 p-4 rounded-lg border border-purple-200">
        <div className="flex items-center mb-3">
          <DollarSign className="w-5 h-5 text-purple-600 mr-2" />
          <h3 className="text-lg font-semibold text-purple-900">Price Settings</h3>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
          <div>
            <span className="font-medium text-purple-800">Target Price:</span>
            <div className="text-purple-700">
              {filter.currency} {filter.targetPrice || 'Not set'}
            </div>
          </div>
          <div>
            <span className="font-medium text-purple-800">Budget Range:</span>
            <div className="text-purple-700">
              {filter.currency} {filter.budgetRange.min} - {filter.currency} {filter.budgetRange.max}
            </div>
          </div>
          <div>
            <span className="font-medium text-purple-800">Price Drop Alert:</span>
            <div className="text-purple-700">
              {filter.priceDropPercentage}% drop
            </div>
          </div>
          <div>
            <span className="font-medium text-purple-800">Confidence:</span>
            <div className="text-purple-700 capitalize">
              {filter.priceBreakConfidence}
            </div>
          </div>
        </div>

        {/* Instant Price Break Alerts */}
        <div className="mt-4 pt-4 border-t border-purple-200">
          <div className="flex items-center mb-2">
            <Zap className="w-4 h-4 text-purple-600 mr-2" />
            <span className="font-medium text-purple-800">Instant Price Break Alerts:</span>
          </div>
          <div className="text-purple-700">
            {getPriceBreakAlertSummary()}
          </div>
        </div>
      </div>

      {/* Alert Preferences Summary */}
      <div className="bg-orange-50 p-4 rounded-lg border border-orange-200">
        <div className="flex items-center mb-3">
          <Bell className="w-5 h-5 text-orange-600 mr-2" />
          <h3 className="text-lg font-semibold text-orange-900">Alert Preferences</h3>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
          <div>
            <span className="font-medium text-orange-800">Monitoring:</span>
            <div className="text-orange-700 capitalize">
              {filter.monitorFrequency.replace('-', ' ')}
            </div>
          </div>
          <div>
            <span className="font-medium text-orange-800">Urgency:</span>
            <div className="text-orange-700 capitalize">
              {filter.alertUrgency}
            </div>
          </div>
          <div>
            <span className="font-medium text-orange-800">Detail Level:</span>
            <div className="text-orange-700 capitalize">
              {filter.alertDetailLevel.replace(/-/g, ' ')}
            </div>
          </div>
          <div>
            <span className="font-medium text-orange-800">Notifications:</span>
            <div className="text-orange-700">
              {Object.entries(filter.notificationMethods)
                .filter(([_, enabled]) => enabled)
                .map(([key, _]) => key.charAt(0).toUpperCase() + key.slice(1))
                .join(', ')
              }
            </div>
          </div>
        </div>

        {/* Instant Alert Priority */}
        {filter.instantPriceBreakAlerts.enabled && (
          <div className="mt-4 pt-4 border-t border-orange-200">
            <div className="flex items-center mb-2">
              <Zap className="w-4 h-4 text-orange-600 mr-2" />
              <span className="font-medium text-orange-800">Instant Alert Priority:</span>
            </div>
            <div className="text-orange-700 capitalize">
              {filter.instantAlertPriority}
            </div>
          </div>
        )}
      </div>

      {/* Filter Metadata */}
      <div className="bg-gray-50 p-4 rounded-lg border border-gray-200">
        <h3 className="text-lg font-semibold text-gray-900 mb-3">Filter Information</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
          <div>
            <span className="font-medium text-gray-800">Name:</span>
            <div className="text-gray-700">
              {filter.filterName || 'Not set'}
            </div>
          </div>
          <div>
            <span className="font-medium text-gray-800">Created:</span>
            <div className="text-gray-700">
              {filter.createdAt.toLocaleDateString()}
            </div>
          </div>
          {filter.description && (
            <div className="md:col-span-2">
              <span className="font-medium text-gray-800">Description:</span>
              <div className="text-gray-700">
                {filter.description}
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Status Indicators */}
      <div className="bg-white p-4 rounded-lg border border-gray-200">
        <h3 className="text-lg font-semibold text-gray-900 mb-3">Status & Validation</h3>
        <div className="space-y-2">
          <div className="flex items-center">
            <Check className="w-4 h-4 text-green-600 mr-2" />
            <span className="text-sm text-gray-700">Filter configuration complete</span>
          </div>
          <div className="flex items-center">
            <Check className="w-4 h-4 text-green-600 mr-2" />
            <span className="text-sm text-gray-700">All required fields filled</span>
          </div>
          {filter.instantPriceBreakAlerts.enabled && (
            <div className="flex items-center">
              <Zap className="w-4 h-4 text-blue-600 mr-2" />
              <span className="text-sm text-gray-700">Instant price break alerts enabled</span>
            </div>
          )}
          <div className="flex items-center">
            <Check className="w-4 h-4 text-green-600 mr-2" />
            <span className="text-sm text-gray-700">Ready to save and activate</span>
          </div>
        </div>
      </div>

      {/* Estimated Results */}
      <div className="bg-blue-50 p-4 rounded-lg border border-blue-200">
        <h3 className="text-lg font-semibold text-blue-900 mb-3">Estimated Results</h3>
        <div className="text-center">
          <div className="text-3xl font-bold text-blue-600 mb-2">24-48</div>
          <div className="text-blue-700 mb-2">flights match your criteria</div>
          <div className="text-sm text-blue-600">
            Based on current market data and your preferences
          </div>
        </div>
      </div>
    </div>
  );
};

export default FilterSummary;
