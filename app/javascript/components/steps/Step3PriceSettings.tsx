import React, { useState } from 'react';
import { DollarSign, Zap, TrendingUp, TrendingDown, Minus, Info, AlertTriangle } from 'lucide-react';
import { FlightFilter, ValidationError, PriceBreakExample, HistoricalPriceData } from '../../types/flight-filter';

interface Step3PriceSettingsProps {
  filter: FlightFilter;
  updateFilter: (updates: Partial<FlightFilter>) => void;
  errors: ValidationError[];
  priceBreakExamples: PriceBreakExample[];
  historicalData: HistoricalPriceData[];
}

const Step3PriceSettings: React.FC<Step3PriceSettingsProps> = ({ 
  filter, 
  updateFilter, 
  errors, 
  priceBreakExamples, 
  historicalData 
}) => {
  const [showFlexibilityOptions, setShowFlexibilityOptions] = useState(false);

  const currencies = ['USD', 'EUR', 'GBP', 'CAD', 'AUD', 'JPY'];
  
  const confidenceLevels = [
    { value: 'low', label: 'Low', description: 'Unlikely to hit target', color: 'text-red-600', icon: TrendingUp },
    { value: 'medium', label: 'Medium', description: 'Moderate chance', color: 'text-yellow-600', icon: Minus },
    { value: 'high', label: 'High', description: 'Very likely to hit', color: 'text-green-600', icon: TrendingDown }
  ];

  const getError = (field: string) => {
    return errors.find(error => error.field === field)?.message;
  };

  const getPriceBreakConfidenceColor = (confidence: string) => {
    switch (confidence) {
      case 'high': return 'text-green-600';
      case 'medium': return 'text-yellow-600';
      case 'low': return 'text-red-600';
      default: return 'text-gray-600';
    }
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

  return (
    <div className="space-y-6">
      <div className="text-center mb-6">
        <h2 className="text-2xl font-bold text-gray-900 mb-2">Price Settings</h2>
        <p className="text-gray-600">Set your budget and price alert preferences</p>
      </div>

      {/* Target Price */}
      <div className="bg-gray-50 p-4 rounded-lg">
        <h3 className="font-semibold text-gray-900 mb-3 flex items-center">
          <DollarSign className="w-4 h-4 mr-2" />
          Target Price
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
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
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              />
              <div className="absolute right-3 top-3.5 text-gray-500">
                {filter.currency}
              </div>
            </div>
            {getError('targetPrice') && (
              <p className="mt-1 text-sm text-red-600">{getError('targetPrice')}</p>
            )}
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Currency
            </label>
            <select
              value={filter.currency}
              onChange={(e) => updateFilter({ currency: e.target.value })}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              {currencies.map(currency => (
                <option key={currency} value={currency}>{currency}</option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Instant Price Break Alerts */}
      <div className="bg-gradient-to-r from-blue-50 to-purple-50 p-6 rounded-lg border-2 border-blue-200">
        <div className="flex items-center mb-4">
          <Zap className="w-6 h-6 text-blue-600 mr-2" />
          <h3 className="text-xl font-bold text-blue-900">⚡ INSTANT PRICE BREAK ALERTS</h3>
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
              className="h-5 w-5 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
            />
            <span className="ml-2 text-lg font-semibold text-blue-900">
              Enable instant price break notifications
            </span>
          </label>
        </div>

        {filter.instantPriceBreakAlerts.enabled && (
          <div className="space-y-4">
            {/* Alert Type Selection */}
            <div className="bg-white p-4 rounded-lg border border-blue-200">
              <h4 className="font-semibold text-gray-900 mb-3">Alert Type</h4>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                <button
                  onClick={() => updateFilter({
                    instantPriceBreakAlerts: {
                      ...filter.instantPriceBreakAlerts,
                      type: 'exact-match'
                    }
                  })}
                  className={`p-4 rounded-lg border-2 transition-colors text-left ${
                    filter.instantPriceBreakAlerts.type === 'exact-match'
                      ? 'border-green-500 bg-green-50 text-green-700'
                      : 'border-gray-300 bg-white text-gray-700 hover:border-gray-400'
                  }`}
                >
                  <div className="font-medium text-lg">✅ Exact Match</div>
                  <div className="text-sm text-gray-600 mt-1">
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
                  className={`p-4 rounded-lg border-2 transition-colors text-left ${
                    filter.instantPriceBreakAlerts.type === 'flexible-match'
                      ? 'border-blue-500 bg-blue-50 text-blue-700'
                      : 'border-gray-300 bg-white text-gray-700 hover:border-gray-400'
                  }`}
                >
                  <div className="font-medium text-lg">⚡ Flexible Match</div>
                  <div className="text-sm text-gray-600 mt-1">
                    Alert me when price drops below ${filter.targetPrice} EVEN IF some filter criteria don't match
                  </div>
                </button>
              </div>
            </div>

            {/* Flexibility Options */}
            {filter.instantPriceBreakAlerts.type === 'flexible-match' && (
              <div className="bg-white p-4 rounded-lg border border-blue-200">
                <h4 className="font-semibold text-gray-900 mb-3">Flexibility Options</h4>
                <p className="text-sm text-gray-600 mb-3">
                  Select which criteria can be flexible for partial match alerts:
                </p>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                  {(['airline', 'stops', 'times', 'dates'] as const).map((option) => (
                    <label key={option} className="flex items-center p-3 border border-gray-200 rounded-lg hover:bg-gray-50">
                      <input
                        type="checkbox"
                        checked={filter.instantPriceBreakAlerts.flexibilityOptions[option]}
                        onChange={(e) => updateFlexibilityOption(option, e.target.checked)}
                        className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
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
            <div className="bg-yellow-50 p-4 rounded-lg border border-yellow-200">
              <div className="flex items-start">
                <AlertTriangle className="w-5 h-5 text-yellow-600 mr-2 mt-0.5 flex-shrink-0" />
                <div>
                  <h4 className="font-medium text-yellow-800">High Priority Monitoring</h4>
                  <p className="text-sm text-yellow-700 mt-1">
                    Instant price break alerts require real-time monitoring, which may increase battery usage and data consumption.
                  </p>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Price Drop Percentage */}
      <div className="bg-gray-50 p-4 rounded-lg">
        <h3 className="font-semibold text-gray-900 mb-3">Price Drop Percentage Alert</h3>
        <div className="flex items-center space-x-4">
          <label className="text-sm font-medium text-gray-700">
            Alert me on
          </label>
          <select
            value={filter.priceDropPercentage}
            onChange={(e) => updateFilter({ priceDropPercentage: parseInt(e.target.value) })}
            className="px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          >
            <option value={10}>10%</option>
            <option value={15}>15%</option>
            <option value={20}>20%</option>
            <option value={25}>25%</option>
            <option value={30}>30%</option>
          </select>
          <span className="text-sm text-gray-600">price drop</span>
        </div>
      </div>

      {/* Budget Range */}
      <div className="bg-gray-50 p-4 rounded-lg">
        <h3 className="font-semibold text-gray-900 mb-3">Budget Range</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
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
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
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
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
          </div>
        </div>
        
        {getError('budgetRange') && (
          <p className="mt-2 text-sm text-red-600">{getError('budgetRange')}</p>
        )}
      </div>

      {/* Price Break Confidence */}
      <div className="bg-gray-50 p-4 rounded-lg">
        <h3 className="font-semibold text-gray-900 mb-3">Price Break Confidence</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
          {confidenceLevels.map((level) => {
            const Icon = level.icon;
            return (
              <button
                key={level.value}
                onClick={() => updateFilter({ priceBreakConfidence: level.value as any })}
                className={`p-4 rounded-lg border-2 transition-colors text-center ${
                  filter.priceBreakConfidence === level.value
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

      {/* Historical Price Chart */}
      <div className="bg-gray-50 p-4 rounded-lg">
        <h3 className="font-semibold text-gray-900 mb-3">Historical Price Trends</h3>
        <div className="bg-white p-4 rounded-lg border">
          <div className="flex items-center justify-between mb-4">
            <div className="text-sm text-gray-600">
              Last 5 months price trend
            </div>
            <div className="text-sm font-medium text-gray-900">
              Current: ${historicalData[historicalData.length - 1]?.price || 0}
            </div>
          </div>
          
          <div className="flex items-end justify-between h-32">
            {historicalData.map((data, index) => (
              <div key={index} className="flex flex-col items-center">
                <div className="text-xs text-gray-500 mb-1">
                  {new Date(data.date).toLocaleDateString('en-US', { month: 'short' })}
                </div>
                <div
                  className="w-8 bg-blue-500 rounded-t"
                  style={{ height: `${(data.price / 500) * 100}%` }}
                ></div>
                <div className="text-xs text-gray-600 mt-1">
                  ${data.price}
                </div>
                <div className="mt-1">
                  {data.trend === 'falling' ? (
                    <TrendingDown className="w-3 h-3 text-green-600" />
                  ) : data.trend === 'rising' ? (
                    <TrendingUp className="w-3 h-3 text-red-600" />
                  ) : (
                    <Minus className="w-3 h-3 text-gray-400" />
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Price Break Examples */}
      <div className="bg-gray-50 p-4 rounded-lg">
        <h3 className="font-semibold text-gray-900 mb-3">Price Break Examples</h3>
        <div className="space-y-3">
          {priceBreakExamples.map((example, index) => (
            <div key={index} className="bg-white p-4 rounded-lg border">
              <div className="flex items-center justify-between mb-2">
                <div className="font-medium text-sm">{example.title}</div>
                <div className={`flex items-center text-xs ${getPriceBreakConfidenceColor(example.confidence)}`}>
                  {getPriceBreakConfidenceIcon(example.confidence)}
                  <span className="ml-1 capitalize">{example.confidence} confidence</span>
                </div>
              </div>
              <div className="text-sm text-gray-600 mb-2">{example.description}</div>
              <div className="flex justify-between items-center">
                <span className="text-sm font-semibold text-green-600">
                  ${example.price}
                </span>
                <span className="text-xs text-gray-500">
                  Save ${example.savings}
                </span>
              </div>
              {example.differences && (
                <div className="mt-2 text-xs text-gray-500">
                  {example.differences.map((diff, i) => (
                    <div key={i} className="flex items-center">
                      <AlertTriangle className="w-3 h-3 mr-1 text-yellow-500" />
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
      <div className="bg-green-50 p-4 rounded-lg border border-green-200">
        <h3 className="font-medium text-green-800 mb-2">Price Settings Summary</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm text-green-700">
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
