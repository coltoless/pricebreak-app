import React from 'react';
import { DollarSign, Zap, TrendingUp, TrendingDown, Minus, Info, AlertTriangle } from 'lucide-react';
import { FlightFilter, ValidationError, PriceBreakExample, HistoricalPriceData } from '../../types/flight-filter';

interface Step3PriceSettingsProps {
  filter: FlightFilter;
  updateFilter: (updates: Partial<FlightFilter>) => void;
  errors: ValidationError[];
  priceBreakExamples?: PriceBreakExample[];
  historicalData?: HistoricalPriceData[];
}

const Step3PriceSettings: React.FC<Step3PriceSettingsProps> = ({
  filter,
  updateFilter,
  errors,
  priceBreakExamples,
  historicalData,
}) => {

  const currencies = ['USD', 'EUR', 'GBP', 'CAD', 'AUD', 'JPY'];
  
  const confidenceLevels = [
    { value: 'low', label: 'Low', description: 'Unlikely to hit target', icon: TrendingUp },
    { value: 'medium', label: 'Medium', description: 'Moderate chance', icon: Minus },
    { value: 'high', label: 'High', description: 'Very likely to hit', icon: TrendingDown }
  ];

  const getError = (field: string) => {
    return errors.find(error => error.field === field)?.message;
  };

  const getPriceBreakConfidenceIcon = (confidence: string) => {
    switch (confidence) {
      case 'high': return <TrendingDown className="w-4 h-4" />;
      case 'medium': return <Minus className="w-4 h-4" />;
      case 'low': return <TrendingUp className="w-4 h-4" />;
      default: return <Minus className="w-4 h-4" />;
    }
  };

  const updateFlexibilityOption = (option: keyof typeof filter.instantPriceBreakAlerts.flexibilityOptions, value: boolean) => {
    updateFilter({
      instantPriceBreakAlerts: {
        ...filter.instantPriceBreakAlerts,
        flexibilityOptions: {
          ...filter.instantPriceBreakAlerts.flexibilityOptions,
          [option]: value
        }
      }
    });
  };

  const examples = priceBreakExamples ?? [];
  const history = historicalData ?? [];

  return (
    <div className="space-y-8">
      {/* Target Price */}
      <div>
        <label className="mb-4 block text-sm font-semibold uppercase tracking-wide text-[#4C1D95]">
          Target Price (USD)
        </label>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label className="mb-3 block text-sm font-medium text-[#4C1D95]">
              Target Price
            </label>
            <div className="relative">
              <input
                type="number"
                value={filter.targetPrice || ''}
                onChange={(e) => updateFilter({ targetPrice: parseFloat(e.target.value) || 0 })}
                placeholder="0.00"
                min="0"
                step="0.01"
                className="w-full rounded-lg border border-[#E9D5FF] px-4 py-3 text-[#4C1D95] focus:border-[#C4B5FD] focus:ring-2 focus:ring-[#C4B5FD]"
              />
              <div className="absolute right-3 top-3.5 text-[#4C1D95]/60">
                {filter.currency}
              </div>
            </div>
            {getError('targetPrice') && (
              <p className="mt-1 text-sm text-rose-500">{getError('targetPrice')}</p>
            )}
          </div>
          
          <div>
            <label className="mb-2 block text-sm font-medium text-[#4C1D95]">
              Currency
            </label>
            <select
              value={filter.currency}
              onChange={(e) => updateFilter({ currency: e.target.value })}
              className="w-full rounded-lg border border-[#E9D5FF] bg-white px-4 py-3 text-[#4C1D95] focus:border-[#C4B5FD] focus:ring-2 focus:ring-[#C4B5FD]"
            >
              {currencies.map(currency => (
                <option key={currency} value={currency}>{currency}</option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Instant Price Break Alerts */}
      <div className="rounded-2xl border-2 border-[#C4B5FD] bg-gradient-to-r from-[#F5F3FF] via-[#E9D5FF]/70 to-[#C4B5FD]/30 p-6">
        <div className="mb-4 flex items-center">
          <Zap className="mr-2 h-6 w-6 text-[#06B6D4]" />
          <h3 className="text-xl font-bold text-[#4C1D95]">⚡ Instant Price Break Alerts</h3>
        </div>
        
        <div className="mb-4">
          <label className="flex items-center">
            <input
              type="checkbox"
              checked={filter.instantPriceBreakAlerts.enabled}
              onChange={(e) => updateFilter({
                instantPriceBreakAlerts: {
                  ...filter.instantPriceBreakAlerts,
                  enabled: e.target.checked
                }
              })}
              className="h-5 w-5 rounded border-[#E9D5FF] text-[#8B5CF6] focus:ring-[#8B5CF6]"
            />
            <span className="ml-2 text-lg font-semibold text-[#4C1D95]">
              Enable instant price break notifications
            </span>
          </label>
        </div>

        {filter.instantPriceBreakAlerts.enabled && (
          <div className="space-y-4">
            {/* Alert Type Selection */}
            <div className="rounded-xl border border-[#E9D5FF] bg-white p-4 shadow-sm shadow-[#4C1D9510]">
              <h4 className="mb-3 font-semibold text-[#4C1D95]">Alert Type</h4>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                <button
                  onClick={() => updateFilter({
                    instantPriceBreakAlerts: {
                      ...filter.instantPriceBreakAlerts,
                      type: 'exact-match'
                    }
                  })}
                  className={`rounded-lg border-2 p-4 text-left transition-colors ${
                    filter.instantPriceBreakAlerts.type === 'exact-match'
                      ? 'border-transparent bg-gradient-to-br from-[#06B6D4] via-[#14B8A6] to-[#0F766E] text-white shadow-lg shadow-[#0F766E50]'
                      : 'border-[#E9D5FF] bg-white text-[#0F172A] hover:border-[#C4B5FD]'
                  }`}
                >
                  <div className="text-lg font-medium">✅ Exact Match</div>
                  <div className={`mt-1 text-sm ${filter.instantPriceBreakAlerts.type === 'exact-match' ? 'text-white/85' : 'text-[#4C1D95]/70'}`}>
                    Alert me when price drops below ${filter.targetPrice} AND ALL filter criteria match
                  </div>
                </button>
                
                <button
                  onClick={() => updateFilter({
                    instantPriceBreakAlerts: {
                      ...filter.instantPriceBreakAlerts,
                      type: 'flexible-match'
                    }
                  })}
                  className={`rounded-lg border-2 p-4 text-left transition-colors ${
                    filter.instantPriceBreakAlerts.type === 'flexible-match'
                      ? 'border-transparent bg-gradient-to-br from-[#8B5CF6] via-[#7C3AED] to-[#6B21A8] text-white shadow-lg shadow-[#5B21B650]'
                      : 'border-[#E9D5FF] bg-white text-[#4C1D95] hover:border-[#C4B5FD]'
                  }`}
                >
                  <div className="text-lg font-medium">⚡ Flexible Match</div>
                  <div className={`mt-1 text-sm ${filter.instantPriceBreakAlerts.type === 'flexible-match' ? 'text-white/85' : 'text-[#4C1D95]/70'}`}>
                    Alert me when price drops below ${filter.targetPrice} EVEN IF some filter criteria don't match
                  </div>
                </button>
              </div>
            </div>

            {/* Flexibility Options */}
            {filter.instantPriceBreakAlerts.type === 'flexible-match' && (
              <div className="rounded-xl border border-[#E9D5FF] bg-white p-4 shadow-sm shadow-[#4C1D9510]">
                <h4 className="mb-3 font-semibold text-[#4C1D95]">Flexibility Options</h4>
                <p className="mb-3 text-sm text-[#4C1D95]/70">
                  Select which criteria can be flexible for partial match alerts:
                </p>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                  {(['airline', 'stops', 'times', 'dates'] as const).map((option) => (
                    <label
                      key={option}
                      className="flex items-center rounded-lg border border-[#E9D5FF] p-3 text-[#4C1D95] transition hover:border-[#C4B5FD] hover:bg-[#F5F3FF]"
                    >
                      <input
                        type="checkbox"
                        checked={filter.instantPriceBreakAlerts.flexibilityOptions[option]}
                        onChange={(e) => updateFlexibilityOption(option, e.target.checked)}
                        className="h-4 w-4 rounded border-[#E9D5FF] text-[#8B5CF6] focus:ring-[#8B5CF6]"
                      />
                      <span className="ml-2 text-sm font-medium capitalize">
                        {option === 'times' ? 'Times' : option}
                      </span>
                    </label>
                  ))}
                </div>
              </div>
            )}

            {/* Warning for Real-time Monitoring */}
            <div className="rounded-xl border border-[#FBCFE8] bg-[#FDF2F8] p-4">
              <div className="flex items-start">
                <AlertTriangle className="mr-2 mt-0.5 h-5 w-5 flex-shrink-0 text-[#EC4899]" />
                <div>
                  <h4 className="font-medium text-[#831843]">High Priority Monitoring</h4>
                  <p className="mt-1 text-sm text-[#9D174D]">
                    Instant price break alerts require real-time monitoring, which may increase battery usage and data consumption.
                  </p>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Price Drop Percentage */}
      <div className="rounded-xl border border-[#E9D5FF] bg-[#F5F3FF] p-4">
        <h3 className="mb-3 font-semibold text-[#4C1D95]">Price Drop Percentage Alert</h3>
        <div className="flex items-center space-x-4">
          <label className="text-sm font-medium text-[#4C1D95]">
            Alert me on
          </label>
          <select
            value={filter.priceDropPercentage}
            onChange={(e) => updateFilter({ priceDropPercentage: parseInt(e.target.value) })}
            className="rounded-md border border-[#E9D5FF] bg-white px-3 py-2 text-[#4C1D95] focus:border-[#C4B5FD] focus:ring-2 focus:ring-[#C4B5FD]"
          >
            <option value={10}>10%</option>
            <option value={15}>15%</option>
            <option value={20}>20%</option>
            <option value={25}>25%</option>
            <option value={30}>30%</option>
          </select>
          <span className="text-sm text-[#4C1D95]/70">price drop</span>
        </div>
      </div>

      {/* Budget Range */}
      <div className="rounded-xl border border-[#E9D5FF] bg-[#F5F3FF] p-4">
        <h3 className="mb-3 font-semibold text-[#4C1D95]">Budget Range</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="mb-2 block text-sm font-medium text-[#4C1D95]">
              Minimum Price
            </label>
            <input
              type="number"
              value={filter.budgetRange.min || ''}
              onChange={(e) => updateFilter({
                budgetRange: {
                  ...filter.budgetRange,
                  min: parseFloat(e.target.value) || 0
                }
              })}
              placeholder="0.00"
              min="0"
              step="0.01"
              className="w-full rounded-lg border border-[#E9D5FF] px-4 py-3 text-[#4C1D95] focus:border-[#C4B5FD] focus:ring-2 focus:ring-[#C4B5FD]"
            />
          </div>
          
          <div>
            <label className="mb-2 block text-sm font-medium text-[#4C1D95]">
              Maximum Price
            </label>
            <input
              type="number"
              value={filter.budgetRange.max || ''}
              onChange={(e) => updateFilter({
                budgetRange: {
                  ...filter.budgetRange,
                  max: parseFloat(e.target.value) || 0
                }
              })}
              placeholder="1000.00"
              min="0"
              step="0.01"
              className="w-full rounded-lg border border-[#E9D5FF] px-4 py-3 text-[#4C1D95] focus:border-[#C4B5FD] focus:ring-2 focus:ring-[#C4B5FD]"
            />
          </div>
        </div>
        
        {getError('budgetRange') && (
          <p className="mt-2 text-sm text-rose-500">{getError('budgetRange')}</p>
        )}
      </div>

      {/* Price Break Confidence */}
      <div className="rounded-xl border border-[#E9D5FF] bg-[#F5F3FF] p-4">
        <h3 className="mb-3 font-semibold text-[#4C1D95]">Price Break Confidence</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
          {confidenceLevels.map((level) => {
            const Icon = level.icon;
            return (
              <button
                key={level.value}
                onClick={() => updateFilter({ priceBreakConfidence: level.value as any })}
                className={`rounded-lg border-2 p-4 text-center transition-colors ${
                  filter.priceBreakConfidence === level.value
                    ? 'border-transparent bg-gradient-to-br from-[#8B5CF6] via-[#7C3AED] to-[#6B21A8] text-white shadow-lg shadow-[#5B21B650]'
                    : 'border-[#E9D5FF] bg-white text-[#4C1D95] hover:border-[#C4B5FD]'
                }`}
              >
                <Icon
                  className={`mx-auto mb-2 h-6 w-6 ${
                    filter.priceBreakConfidence === level.value
                      ? 'text-white'
                      : 'text-[#7C3AED]'
                  }`}
                />
                <div className="font-medium">{level.label}</div>
                <div
                  className={`text-sm ${
                    filter.priceBreakConfidence === level.value
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

      {/* Historical Price Chart */}
      {history.length > 0 && (
      <div className="rounded-xl border border-[#E9D5FF] bg-[#F5F3FF] p-4">
        <h3 className="mb-3 font-semibold text-[#4C1D95]">Historical Price Trends</h3>
        <div className="rounded-xl border border-[#E9D5FF] bg-white p-4 shadow-sm shadow-[#4C1D9510]">
          <div className="mb-4 flex items-center justify-between">
            <div className="text-sm text-[#4C1D95]/70">
              Last 5 months price trend
            </div>
            <div className="text-sm font-medium text-[#4C1D95]">
              Current: ${history[history.length - 1]?.price || 0}
            </div>
          </div>
          
          <div className="flex h-32 items-end justify-between">
            {history.map((data, index) => (
              <div key={index} className="flex flex-col items-center">
                <div className="mb-1 text-xs text-[#4C1D95]/60">
                  {new Date(data.date).toLocaleDateString('en-US', { month: 'short' })}
                </div>
                <div
                  className="w-8 rounded-t bg-gradient-to-t from-[#8B5CF6] via-[#7C3AED] to-[#06B6D4]"
                  style={{ height: `${(data.price / 500) * 100}%` }}
                ></div>
                <div className="mt-1 text-xs text-[#4C1D95]/70">
                  ${data.price}
                </div>
                <div className="mt-1">
                  {data.trend === 'falling' ? (
                    <TrendingDown className="h-3 w-3 text-[#14B8A6]" />
                  ) : data.trend === 'rising' ? (
                    <TrendingUp className="h-3 w-3 text-[#F97316]" />
                  ) : (
                    <Minus className="h-3 w-3 text-[#4C1D95]/50" />
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
      )}

      {/* Price Break Examples */}
      <div className="rounded-xl border border-[#E9D5FF] bg-[#F5F3FF] p-4">
        <h3 className="mb-3 font-semibold text-[#4C1D95]">Price Break Examples</h3>
        <div className="space-y-3">
          {examples.map((example, index) => (
            <div key={index} className="rounded-xl border border-[#E9D5FF] bg-white p-4 shadow-sm shadow-[#4C1D9510]">
              <div className="mb-2 flex items-center justify-between">
                <div className="text-sm font-medium text-[#4C1D95]">{example.title}</div>
                <div className={`flex items-center text-xs text-[#4C1D95]`}>
                  {getPriceBreakConfidenceIcon(example.confidence)}
                  <span className="ml-1 capitalize">
                    {example.confidence} confidence
                  </span>
                </div>
              </div>
              <div className="mb-2 text-sm text-[#4C1D95]/70">
                {example.description}
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm font-semibold text-[#06B6D4]">
                  ${example.price}
                </span>
                <span className="text-xs text-[#4C1D95]/60">
                  Save ${example.savings}
                </span>
              </div>
              {example.differences && (
                <div className="mt-2 text-xs text-[#4C1D95]/60">
                  {example.differences.map((diff, i) => (
                    <div key={i} className="flex items-center">
                      <AlertTriangle className="mr-1 h-3 w-3 text-[#EC4899]" />
                      {diff}
                    </div>
                  ))}
                </div>
              )}
            </div>
          ))}
        </div>
      </div>

      {/* Price Settings Summary */}
      <div className="rounded-xl border border-[#14B8A6]/40 bg-gradient-to-r from-[#0ea5e9]/20 via-[#06B6D4]/20 to-transparent p-4 text-[#0f172a]">
        <h3 className="mb-2 font-medium text-[#0f172a]">Price Settings Summary</h3>
        <div className="grid grid-cols-1 gap-4 text-sm text-[#0f172a]/80 md:grid-cols-2">
          <div>
            <span className="font-medium">Target Price:</span> {filter.currency} {filter.targetPrice}
          </div>
          <div>
            <span className="font-medium">Budget Range:</span> {filter.currency} {filter.budgetRange.min} - {filter.currency} {filter.budgetRange.max}
          </div>
          <div>
            <span className="font-medium">Price Break Alerts:</span> {filter.instantPriceBreakAlerts.enabled ? 'Enabled' : 'Disabled'}
          </div>
          <div>
            <span className="font-medium">Alert Type:</span> {filter.instantPriceBreakAlerts.enabled ? filter.instantPriceBreakAlerts.type.replace('-', ' ').replace(/\b\w/g, l => l.toUpperCase()) : 'N/A'}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Step3PriceSettings;

