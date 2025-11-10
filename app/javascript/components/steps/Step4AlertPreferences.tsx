import React from 'react';
import { Bell, Clock, AlertTriangle, Mail, MessageSquare, Smartphone, Monitor, Info, Zap, Gauge, TrendingUp } from 'lucide-react';
import { FlightFilter, ValidationError } from '../../types/flight-filter';

interface Step4AlertPreferencesProps {
  filter: FlightFilter;
  updateFilter: (updates: Partial<FlightFilter>) => void;
  errors: ValidationError[];
}

const Step4AlertPreferences: React.FC<Step4AlertPreferencesProps> = ({ filter, updateFilter, errors }) => {
  const monitoringFrequencies = [
    { value: 'real-time', label: 'Real-time', description: 'Instant notifications', icon: Zap, accent: 'text-[#06B6D4]' },
    { value: 'hourly', label: 'Hourly', description: 'Updates every hour', icon: Clock, accent: 'text-[#0EA5E9]' },
    { value: 'daily', label: 'Daily', description: 'Daily summary', icon: Clock, accent: 'text-[#7C3AED]' },
    { value: 'weekly', label: 'Weekly', description: 'Weekly summary', icon: Clock, accent: 'text-[#4C1D95]' }
  ];

  const alertUrgencyLevels = [
    { value: 'patient', label: 'Patient', description: 'Relaxed monitoring', icon: Gauge, accent: 'text-[#06B6D4]' },
    { value: 'moderate', label: 'Moderate', description: 'Balanced approach', icon: Gauge, accent: 'text-[#F97316]' },
    { value: 'urgent', label: 'Urgent', description: 'Aggressive monitoring', icon: AlertTriangle, accent: 'text-[#EC4899]' }
  ];

  const instantAlertPriorities = [
    { value: 'normal', label: 'Normal', description: 'Standard priority', icon: Bell, accent: 'text-[#7C3AED]' },
    { value: 'high', label: 'High Priority', description: 'Elevated importance', icon: TrendingUp, accent: 'text-[#0EA5E9]' },
    { value: 'critical', label: 'Critical', description: 'Maximum urgency', icon: AlertTriangle, accent: 'text-[#EC4899]' }
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
      <div className="mb-6 text-center">
        <h2 className="mb-2 text-2xl font-bold text-[#4C1D95]">Alert Preferences</h2>
        <p className="text-[#4C1D95]/70">Configure how and when you want to be notified</p>
      </div>

      {/* Filter Metadata */}
      <div className="rounded-xl border border-[#E9D5FF] bg-[#F5F3FF] p-4">
        <h3 className="mb-3 font-semibold text-[#4C1D95]">Filter Information</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="mb-2 block text-sm font-medium text-[#4C1D95]">
              Filter Name *
            </label>
            <input
              type="text"
              value={filter.filterName}
              onChange={(e) => updateFilter({ filterName: e.target.value })}
              placeholder="e.g., LAX to NYC Business Travel"
              className="w-full rounded-lg border border-[#E9D5FF] px-4 py-3 text-[#4C1D95] focus:border-[#C4B5FD] focus:ring-2 focus:ring-[#C4B5FD]"
            />
            {getError('filterName') && (
              <p className="mt-1 text-sm text-rose-500">{getError('filterName')}</p>
            )}
          </div>
          
          <div>
            <label className="mb-2 block text-sm font-medium text-[#4C1D95]">
              Description
            </label>
            <textarea
              value={filter.description}
              onChange={(e) => updateFilter({ description: e.target.value })}
              placeholder="Optional description of this filter..."
              rows={3}
              className="w-full rounded-lg border border-[#E9D5FF] px-4 py-3 text-[#4C1D95] focus:border-[#C4B5FD] focus:ring-2 focus:ring-[#C4B5FD]"
            />
          </div>
        </div>
      </div>

      {/* Monitoring Frequency */}
      <div className="rounded-xl border border-[#E9D5FF] bg-[#F5F3FF] p-4">
        <h3 className="mb-3 flex items-center font-semibold text-[#4C1D95]">
          <Clock className="mr-2 h-4 w-4 text-[#7C3AED]" />
          Monitoring Frequency
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3">
          {monitoringFrequencies.map((freq) => {
            const Icon = freq.icon;
            return (
              <button
                key={freq.value}
                onClick={() => updateFilter({ monitorFrequency: freq.value as any })}
                className={`rounded-lg border-2 p-4 text-center transition-colors ${
                  filter.monitorFrequency === freq.value
                    ? 'border-transparent bg-gradient-to-br from-[#8B5CF6] via-[#7C3AED] to-[#6B21A8] text-white shadow-lg shadow-[#5B21B650]'
                    : 'border-[#E9D5FF] bg-white text-[#4C1D95] hover:border-[#C4B5FD]'
                }`}
              >
                <Icon
                  className={`mx-auto mb-2 h-6 w-6 ${
                    filter.monitorFrequency === freq.value ? 'text-white' : freq.accent
                  }`}
                />
                <div className="font-medium">{freq.label}</div>
                <div
                  className={`text-sm ${
                    filter.monitorFrequency === freq.value
                      ? 'text-white/80'
                      : 'text-[#4C1D95]/70'
                  }`}
                >
                  {freq.description}
                </div>
              </button>
            );
          })}
        </div>
        
        {filter.monitorFrequency === 'real-time' && (
          <div className="mt-3 rounded-lg border border-[#FBCFE8] bg-[#FDF2F8] p-3">
            <div className="flex items-start">
              <AlertTriangle className="mr-2 mt-0.5 h-4 w-4 flex-shrink-0 text-[#EC4899]" />
              <div className="text-sm text-[#9D174D]">
                <strong>Real-time monitoring</strong> provides instant alerts but may increase battery usage and data consumption.
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Alert Urgency Level */}
      <div className="rounded-xl border border-[#E9D5FF] bg-[#F5F3FF] p-4">
        <h3 className="mb-3 flex items-center font-semibold text-[#4C1D95]">
          <AlertTriangle className="mr-2 h-4 w-4 text-[#EC4899]" />
          Alert Urgency Level
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
          {alertUrgencyLevels.map((level) => {
            const Icon = level.icon;
            return (
              <button
                key={level.value}
                onClick={() => updateFilter({ alertUrgency: level.value as any })}
                className={`rounded-lg border-2 p-4 text-center transition-colors ${
                  filter.alertUrgency === level.value
                    ? 'border-transparent bg-gradient-to-br from-[#8B5CF6] via-[#7C3AED] to-[#6B21A8] text-white shadow-lg shadow-[#5B21B650]'
                    : 'border-[#E9D5FF] bg-white text-[#4C1D95] hover:border-[#C4B5FD]'
                }`}
              >
                <Icon
                  className={`mx-auto mb-2 h-6 w-6 ${
                    filter.alertUrgency === level.value ? 'text-white' : level.accent
                  }`}
                />
                <div className="font-medium">{level.label}</div>
                <div
                  className={`text-sm ${
                    filter.alertUrgency === level.value
                      ? 'text-white/80'
                      : 'text-[#4C1D95]/70'
                  }`}
                >
                  {level.description}
                </div>
              </button>
            );
          })}
        </div>
      </div>

      {/* Instant Alert Priority */}
      {filter.instantPriceBreakAlerts.enabled && (
        <div className="rounded-2xl border-2 border-[#FBCFE8] bg-gradient-to-r from-[#FDF2F8] via-[#FDE68A]/40 to-[#FDF2F8] p-4">
          <h3 className="mb-3 flex items-center font-semibold text-[#9D174D]">
            <Zap className="mr-2 h-5 w-5 text-[#06B6D4]" />
            ⚡ Instant Alert Priority
          </h3>
          <p className="mb-3 text-sm text-[#9D174D]">
            When price break alerts are enabled, these settings control notification priority:
          </p>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
            {instantAlertPriorities.map((priority) => {
              const Icon = priority.icon;
              return (
                <button
                  key={priority.value}
                  onClick={() => updateFilter({ instantAlertPriority: priority.value as any })}
                  className={`rounded-lg border-2 p-4 text-center transition-colors ${
                    filter.instantAlertPriority === priority.value
                      ? 'border-transparent bg-gradient-to-br from-[#8B5CF6] via-[#7C3AED] to-[#6B21A8] text-white shadow-lg shadow-[#5B21B650]'
                      : 'border-[#E9D5FF] bg-white text-[#4C1D95] hover:border-[#C4B5FD]'
                  }`}
                >
                  <Icon
                    className={`mx-auto mb-2 h-6 w-6 ${
                      filter.instantAlertPriority === priority.value
                        ? 'text-white'
                        : priority.accent
                    }`}
                  />
                  <div className="font-medium">{priority.label}</div>
                  <div
                    className={`text-sm ${
                      filter.instantAlertPriority === priority.value
                        ? 'text-white/80'
                        : 'text-[#4C1D95]/70'
                    }`}
                  >
                    {priority.description}
                  </div>
                </button>
              );
            })}
          </div>
        </div>
      )}

      {/* Alert Detail Level */}
      <div className="rounded-xl border border-[#E9D5FF] bg-[#F5F3FF] p-4">
        <h3 className="mb-3 font-semibold text-[#4C1D95]">Alert Detail Level</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          {alertDetailLevels.map((level) => (
            <button
              key={level.value}
              onClick={() => updateFilter({ alertDetailLevel: level.value as any })}
              className={`rounded-lg border-2 p-4 text-left transition-colors ${
                filter.alertDetailLevel === level.value
                  ? 'border-transparent bg-gradient-to-br from-[#8B5CF6] via-[#7C3AED] to-[#6B21A8] text-white shadow-lg shadow-[#5B21B650]'
                  : 'border-[#E9D5FF] bg-white text-[#4C1D95] hover:border-[#C4B5FD]'
              }`}
            >
              <div className="font-medium">{level.label}</div>
              <div
                className={`text-sm ${
                  filter.alertDetailLevel === level.value
                    ? 'text-white/80'
                    : 'text-[#4C1D95]/70'
                }`}
              >
                {level.description}
              </div>
            </button>
          ))}
        </div>
      </div>

      {/* Notification Methods */}
      <div className="rounded-xl border border-[#E9D5FF] bg-[#F5F3FF] p-4">
        <h3 className="mb-3 flex items-center font-semibold text-[#4C1D95]">
          <Bell className="mr-2 h-4 w-4 text-[#7C3AED]" />
          Notification Methods *
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          {notificationMethods.map((method) => {
            const Icon = method.icon;
            return (
              <label
                key={method.key}
                className="flex cursor-pointer items-start rounded-lg border border-[#E9D5FF] bg-white/80 p-4 hover:border-[#C4B5FD] hover:bg-[#F5F3FF]"
              >
                <input
                  type="checkbox"
                  checked={filter.notificationMethods[method.key as keyof typeof filter.notificationMethods]}
                  onChange={() => toggleNotificationMethod(method.key as keyof typeof filter.notificationMethods)}
                  className="mt-0.5 h-5 w-5 rounded border-[#E9D5FF] text-[#8B5CF6] focus:ring-[#8B5CF6]"
                />
                <div className="ml-3">
                  <div className="flex items-center">
                    <Icon className="mr-2 h-5 w-5 text-[#7C3AED]" />
                    <span className="font-medium text-[#4C1D95]">{method.label}</span>
                  </div>
                  <p className="mt-1 text-sm text-[#4C1D95]/70">{method.description}</p>
                </div>
              </label>
            );
          })}
        </div>
        
        {getError('notificationMethods') && (
          <p className="mt-3 text-sm text-rose-500">{getError('notificationMethods')}</p>
        )}
        
        <div className="mt-3 flex items-start">
          <Info className="mr-2 mt-0.5 h-4 w-4 flex-shrink-0 text-[#8B5CF6]" />
          <p className="text-sm text-[#4C1D95]">
            For instant price break alerts, we recommend enabling multiple notification methods to ensure you don't miss important price drops.
          </p>
        </div>
      </div>

      {/* Alert Content Preview */}
      <div className="rounded-xl border border-[#E9D5FF] bg-[#F5F3FF] p-4">
        <h3 className="mb-3 font-semibold text-[#4C1D95]">Alert Content Preview</h3>
        <div className="space-y-3">
          <div className="rounded-lg border border-[#14B8A6]/50 bg-white p-4 shadow-sm shadow-[#0f172a0f]">
            <div className="mb-2 flex items-center">
              <div className="mr-2 h-3 w-3 rounded-full bg-[#14B8A6]" />
              <span className="font-medium text-[#0f172a]">
                ✅ EXACT MATCH: Your ideal flight for $285 (was $340)
              </span>
            </div>
            <div className="text-sm text-[#0f172a]/75">
              Route: LAX → JFK • Date: Dec 15, 2024 • Airline: Delta • Nonstop
            </div>
          </div>
          
          <div className="rounded-lg border border-[#C4B5FD] bg-white p-4 shadow-sm shadow-[#4C1D9510]">
            <div className="mb-2 flex items-center">
              <div className="mr-2 h-3 w-3 rounded-full bg-[#8B5CF6]" />
              <span className="font-medium text-[#4C1D95]">
                ⚡ PRICE BREAK: $275 flight available - Different airline but meets budget
              </span>
            </div>
            <div className="text-sm text-[#4C1D95]/80">
              Route: LAX → JFK • Date: Dec 15, 2024 • Airline: American • 1 stop
            </div>
            <div className="mt-1 text-xs text-[#4C1D95]/60">
              ⚠️ Differences: Different airline, 1 stop instead of nonstop
            </div>
          </div>
        </div>
      </div>

      {/* Alert Preferences Summary */}
      <div className="rounded-xl border border-[#14B8A6]/40 bg-gradient-to-r from-[#0ea5e9]/20 via-[#06B6D4]/20 to-transparent p-4 text-[#0f172a]">
        <h3 className="mb-2 font-medium text-[#0f172a]">Alert Preferences Summary</h3>
        <div className="grid grid-cols-1 gap-4 text-sm text-[#0f172a]/80 md:grid-cols-2">
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
          <div className="mt-3 border-t border-[#14B8A6]/40 pt-3">
            <div className="text-sm text-[#0f172a]/80">
              <span className="font-medium">⚡ Instant Price Break Alerts:</span> {filter.instantAlertPriority.charAt(0).toUpperCase() + filter.instantAlertPriority.slice(1)} Priority
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default Step4AlertPreferences;
