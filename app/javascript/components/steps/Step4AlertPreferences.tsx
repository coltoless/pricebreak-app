import React from 'react';
import { Bell, Clock, AlertTriangle, Mail, MessageSquare, Smartphone, Monitor, Info, Zap } from 'lucide-react';
import { FlightFilter, ValidationError } from '../../types/flight-filter';

interface Step4AlertPreferencesProps {
  filter: FlightFilter;
  updateFilter: (updates: Partial<FlightFilter>) => void;
  errors: ValidationError[];
}

const Step4AlertPreferences: React.FC<Step4AlertPreferencesProps> = ({ filter, updateFilter, errors }) => {
  const monitoringFrequencies = [
    { value: 'real-time', label: 'Real-time', description: 'Instant notifications', icon: Zap, color: 'text-red-600' },
    { value: 'hourly', label: 'Hourly', description: 'Updates every hour', icon: Clock, color: 'text-orange-600' },
    { value: 'daily', label: 'Daily', description: 'Daily summary', icon: Clock, color: 'text-blue-600' },
    { value: 'weekly', label: 'Weekly', description: 'Weekly summary', icon: Clock, color: 'text-gray-600' }
  ];

  const alertUrgencyLevels = [
    { value: 'patient', label: 'Patient', description: 'Relaxed monitoring', color: 'text-green-600' },
    { value: 'moderate', label: 'Moderate', description: 'Balanced approach', color: 'text-yellow-600' },
    { value: 'urgent', label: 'Urgent', description: 'Aggressive monitoring', color: 'text-red-600' }
  ];

  const instantAlertPriorities = [
    { value: 'normal', label: 'Normal', description: 'Standard priority', color: 'text-blue-600' },
    { value: 'high', label: 'High Priority', description: 'Elevated importance', color: 'text-orange-600' },
    { value: 'critical', label: 'Critical', description: 'Maximum urgency', color: 'text-red-600' }
  ];

  const alertDetailLevels = [
    { value: 'exact-matches-only', label: 'Exact Matches Only', description: 'Only perfect matches' },
    { value: 'include-near-matches', label: 'Include Near Matches', description: 'Show similar options with differences highlighted' }
  ];

  const notificationMethods = [
    { key: 'email', label: 'Email', icon: Mail, description: 'Send to your email address' },
    { key: 'sms', label: 'SMS', icon: MessageSquare, description: 'Text message notifications' },
    { key: 'push', label: 'Push Notifications', icon: Smartphone, description: 'Mobile app notifications' },
    { key: 'browser', label: 'Browser Notifications', icon: Monitor, description: 'Desktop browser alerts' }
  ];

  const getError = (field: string) => {
    return errors.find(error => error.field === field)?.message;
  };

  const toggleNotificationMethod = (method: keyof typeof filter.notificationMethods) => {
    updateFilter({
      notificationMethods: {
        ...filter.notificationMethods,
        [method]: !filter.notificationMethods[method]
      }
    });
  };

  return (
    <div className="space-y-6">
      <div className="text-center mb-6">
        <h2 className="text-2xl font-bold text-gray-900 mb-2">Alert Preferences</h2>
        <p className="text-gray-600">Configure how and when you want to be notified</p>
      </div>

      {/* Filter Metadata */}
      <div className="bg-gray-50 p-4 rounded-lg">
        <h3 className="font-semibold text-gray-900 mb-3">Filter Information</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Filter Name *
            </label>
            <input
              type="text"
              value={filter.filterName}
              onChange={(e) => updateFilter({ filterName: e.target.value })}
              placeholder="e.g., LAX to NYC Business Travel"
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
            {getError('filterName') && (
              <p className="mt-1 text-sm text-red-600">{getError('filterName')}</p>
            )}
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Description
            </label>
            <textarea
              value={filter.description}
              onChange={(e) => updateFilter({ description: e.target.value })}
              placeholder="Optional description of this filter..."
              rows={3}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
          </div>
        </div>
      </div>

      {/* Monitoring Frequency */}
      <div className="bg-gray-50 p-4 rounded-lg">
        <h3 className="font-semibold text-gray-900 mb-3 flex items-center">
          <Clock className="w-4 h-4 mr-2" />
          Monitoring Frequency
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3">
          {monitoringFrequencies.map((freq) => {
            const Icon = freq.icon;
            return (
              <button
                key={freq.value}
                onClick={() => updateFilter({ monitorFrequency: freq.value as any })}
                className={`p-4 rounded-lg border-2 transition-colors text-center ${
                  filter.monitorFrequency === freq.value
                    ? 'border-blue-500 bg-blue-50 text-blue-700'
                    : 'border-gray-300 bg-white text-gray-700 hover:border-gray-400'
                }`}
              >
                <Icon className={`w-6 h-6 mx-auto mb-2 ${freq.color}`} />
                <div className="font-medium">{freq.label}</div>
                <div className="text-sm text-gray-600">{freq.description}</div>
              </button>
            );
          })}
        </div>
        
        {filter.monitorFrequency === 'real-time' && (
          <div className="mt-3 p-3 bg-yellow-50 border border-yellow-200 rounded-lg">
            <div className="flex items-start">
              <AlertTriangle className="w-4 h-4 text-yellow-600 mr-2 mt-0.5 flex-shrink-0" />
              <div className="text-sm text-yellow-800">
                <strong>Real-time monitoring</strong> provides instant alerts but may increase battery usage and data consumption.
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Alert Urgency Level */}
      <div className="bg-gray-50 p-4 rounded-lg">
        <h3 className="font-semibold text-gray-900 mb-3 flex items-center">
          <AlertTriangle className="w-4 h-4 mr-2" />
          Alert Urgency Level
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
          {alertUrgencyLevels.map((level) => {
            const Icon = level.icon;
            return (
              <button
                key={level.value}
                onClick={() => updateFilter({ alertUrgency: level.value as any })}
                className={`p-4 rounded-lg border-2 transition-colors text-center ${
                  filter.alertUrgency === level.value
                    ? 'border-blue-500 bg-blue-50 text-blue-700'
                    : 'border-gray-300 bg-white text-gray-700 hover:border-gray-400'
                }`}
              >
                <Icon className={`w-6 h-6 mx-auto mb-2 ${level.color}`} />
                <div className="font-medium">{level.label}</div>
                <div className="text-sm text-gray-600">{level.description}</div>
              </button>
            );
          })}
        </div>
      </div>

      {/* Instant Alert Priority */}
      {filter.instantPriceBreakAlerts.enabled && (
        <div className="bg-gradient-to-r from-orange-50 to-red-50 p-4 rounded-lg border-2 border-orange-200">
          <h3 className="font-semibold text-orange-900 mb-3 flex items-center">
            <Zap className="w-5 h-5 mr-2" />
            ⚡ INSTANT ALERT PRIORITY
          </h3>
          <p className="text-sm text-orange-800 mb-3">
            When price break alerts are enabled, these settings control notification priority:
          </p>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
            {instantAlertPriorities.map((priority) => {
              const Icon = priority.icon;
              return (
                <button
                  key={priority.value}
                  onClick={() => updateFilter({ instantAlertPriority: priority.value as any })}
                  className={`p-4 rounded-lg border-2 transition-colors text-center ${
                    filter.instantAlertPriority === priority.value
                      ? 'border-orange-500 bg-orange-50 text-orange-700'
                      : 'border-gray-300 bg-white text-gray-700 hover:border-gray-400'
                  }`}
                >
                  <Icon className={`w-6 h-6 mx-auto mb-2 ${priority.color}`} />
                  <div className="font-medium">{priority.label}</div>
                  <div className="text-sm text-gray-600">{priority.description}</div>
                </button>
              );
            })}
          </div>
        </div>
      )}

      {/* Alert Detail Level */}
      <div className="bg-gray-50 p-4 rounded-lg">
        <h3 className="font-semibold text-gray-900 mb-3">Alert Detail Level</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          {alertDetailLevels.map((level) => (
            <button
              key={level.value}
              onClick={() => updateFilter({ alertDetailLevel: level.value as any })}
              className={`p-4 rounded-lg border-2 transition-colors text-left ${
                filter.alertDetailLevel === level.value
                  ? 'border-blue-500 bg-blue-50 text-blue-700'
                  : 'border-gray-300 bg-white text-gray-700 hover:border-gray-400'
              }`}
            >
              <div className="font-medium">{level.label}</div>
              <div className="text-sm text-gray-600">{level.description}</div>
            </button>
          ))}
        </div>
      </div>

      {/* Notification Methods */}
      <div className="bg-gray-50 p-4 rounded-lg">
        <h3 className="font-semibold text-gray-900 mb-3 flex items-center">
          <Bell className="w-4 h-4 mr-2" />
          Notification Methods *
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          {notificationMethods.map((method) => {
            const Icon = method.icon;
            return (
              <label key={method.key} className="flex items-start p-4 border border-gray-200 rounded-lg hover:bg-gray-50 cursor-pointer">
                <input
                  type="checkbox"
                  checked={filter.notificationMethods[method.key as keyof typeof filter.notificationMethods]}
                  onChange={() => toggleNotificationMethod(method.key as keyof typeof filter.notificationMethods)}
                  className="h-5 w-5 text-blue-600 focus:ring-blue-500 border-gray-300 rounded mt-0.5"
                />
                <div className="ml-3">
                  <div className="flex items-center">
                    <Icon className="w-5 h-5 text-gray-600 mr-2" />
                    <span className="font-medium text-gray-900">{method.label}</span>
                  </div>
                  <p className="text-sm text-gray-600 mt-1">{method.description}</p>
                </div>
              </label>
            );
          })}
        </div>
        
        {getError('notificationMethods') && (
          <p className="mt-3 text-sm text-red-600">{getError('notificationMethods')}</p>
        )}
        
        <div className="mt-3 flex items-start">
          <Info className="w-4 h-4 text-blue-500 mr-2 mt-0.5 flex-shrink-0" />
          <p className="text-sm text-blue-700">
            For instant price break alerts, we recommend enabling multiple notification methods to ensure you don't miss important price drops.
          </p>
        </div>
      </div>

      {/* Alert Content Preview */}
      <div className="bg-gray-50 p-4 rounded-lg">
        <h3 className="font-semibold text-gray-900 mb-3">Alert Content Preview</h3>
        <div className="space-y-3">
          <div className="bg-white p-4 rounded-lg border border-green-200">
            <div className="flex items-center mb-2">
              <div className="w-3 h-3 bg-green-500 rounded-full mr-2"></div>
              <span className="font-medium text-green-800">✅ EXACT MATCH: Your ideal flight for $285 (was $340)</span>
            </div>
            <div className="text-sm text-green-700">
              Route: LAX → JFK • Date: Dec 15, 2024 • Airline: Delta • Nonstop
            </div>
          </div>
          
          <div className="bg-white p-4 rounded-lg border border-blue-200">
            <div className="flex items-center mb-2">
              <div className="w-3 h-3 bg-blue-500 rounded-full mr-2"></div>
              <span className="font-medium text-blue-800">⚡ PRICE BREAK: $275 flight available - Different airline but meets budget</span>
            </div>
            <div className="text-sm text-blue-700">
              Route: LAX → JFK • Date: Dec 15, 2024 • Airline: American • 1 stop
            </div>
            <div className="text-xs text-gray-600 mt-1">
              ⚠️ Differences: Different airline, 1 stop instead of nonstop
            </div>
          </div>
        </div>
      </div>

      {/* Alert Preferences Summary */}
      <div className="bg-green-50 p-4 rounded-lg border border-green-200">
        <h3 className="font-medium text-green-800 mb-2">Alert Preferences Summary</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm text-green-700">
          <div>
            <span className="font-medium">Monitoring:</span> {filter.monitorFrequency.replace('-', ' ').replace(/\b\w/g, l => l.toUpperCase())}
          </div>
          <div>
            <span className="font-medium">Urgency:</span> {filter.alertUrgency.charAt(0).toUpperCase() + filter.alertUrgency.slice(1)}
          </div>
          <div>
            <span className="font-medium">Detail Level:</span> {filter.alertDetailLevel.replace(/-/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}
          </div>
          <div>
            <span className="font-medium">Notifications:</span> {Object.values(filter.notificationMethods).filter(Boolean).length} method(s)
          </div>
        </div>
        
        {filter.instantPriceBreakAlerts.enabled && (
          <div className="mt-3 pt-3 border-t border-green-200">
            <div className="text-sm text-green-700">
              <span className="font-medium">⚡ Instant Price Break Alerts:</span> {filter.instantAlertPriority.charAt(0).toUpperCase() + filter.instantAlertPriority.slice(1)} Priority
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default Step4AlertPreferences;
