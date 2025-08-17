import React, { useState, useEffect } from 'react';
import { 
  Plane, 
  Calendar, 
  MapPin, 
  Users, 
  DollarSign, 
  Bell, 
  Settings,
  ArrowRight,
  ArrowLeft,
  Check,
  AlertTriangle,
  Zap,
  TrendingUp,
  TrendingDown,
  Minus,
  Plus,
  Info,
  Save,
  Eye,
  Play,
  Copy,
  Share2,
  Star
} from 'lucide-react';
import { 
  FlightFilter, 
  Airport, 
  PriceBreakExample, 
  HistoricalPriceData, 
  PopularRoute, 
  FilterTemplate,
  ValidationError 
} from '../types/flight-filter';

interface FlightPriceFilterProps {
  onSaveFilter?: (filter: FlightFilter) => void;
  onPreviewAlert?: (filter: FlightFilter) => void;
  onTestAlert?: (filter: FlightFilter) => void;
  initialFilter?: Partial<FlightFilter>;
}

const FlightPriceFilter: React.FC<FlightPriceFilterProps> = ({
  onSaveFilter,
  onPreviewAlert,
  onTestAlert,
  initialFilter
}) => {
  const [currentStep, setCurrentStep] = useState(1);
  const [filter, setFilter] = useState<FlightFilter>({
    // Step 1: Route & Dates
    origin: null,
    destination: null,
    tripType: 'round-trip',
    departureDate: null,
    returnDate: null,
    flexibleDates: false,
    dateFlexibility: 3,
    
    // Step 2: Flight Preferences
    cabinClass: 'economy',
    passengers: { adults: 1, children: 0, infants: 0 },
    airlinePreferences: [],
    maxStops: 'nonstop',
    preferredTimes: { departure: [], arrival: [] },
    
    // Step 3: Price Settings
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
    
    // Step 4: Alert Preferences
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
    
    // Metadata
    filterName: '',
    description: '',
    createdAt: new Date(),
    isActive: true
  });

  const [errors, setErrors] = useState<ValidationError[]>([]);
  const [showSummary, setShowSummary] = useState(false);

  // Mock data
  const popularRoutes: PopularRoute[] = [
    {
      origin: { code: 'LAX', name: 'Los Angeles International', city: 'Los Angeles', country: 'USA' },
      destination: { code: 'JFK', name: 'John F. Kennedy International', city: 'New York', country: 'USA' },
      averagePrice: 350,
      bestPrice: 285,
      priceTrend: 'falling'
    },
    {
      origin: { code: 'SFO', name: 'San Francisco International', city: 'San Francisco', country: 'USA' },
      destination: { code: 'ORD', name: 'O\'Hare International', city: 'Chicago', country: 'USA' },
      averagePrice: 320,
      bestPrice: 265,
      priceTrend: 'stable'
    }
  ];

  const filterTemplates: FilterTemplate[] = [
    {
      id: 'business',
      name: 'Business Travel',
      description: 'Premium cabin, flexible dates, priority alerts',
      category: 'business',
      filter: {
        cabinClass: 'business',
        flexibleDates: true,
        instantPriceBreakAlerts: { enabled: true, type: 'exact-match', flexibilityOptions: { airline: false, stops: false, times: false, dates: true } },
        monitorFrequency: 'real-time',
        alertUrgency: 'urgent'
      }
    },
    {
      id: 'vacation',
      name: 'Vacation Planning',
      description: 'Economy class, flexible options, patient monitoring',
      category: 'vacation',
      filter: {
        cabinClass: 'economy',
        flexibleDates: true,
        instantPriceBreakAlerts: { enabled: true, type: 'flexible-match', flexibilityOptions: { airline: true, stops: true, times: true, dates: true } },
        monitorFrequency: 'daily',
        alertUrgency: 'patient'
      }
    }
  ];

  const priceBreakExamples: PriceBreakExample[] = [
    {
      type: 'exact-match',
      title: '✅ EXACT MATCH: Your ideal flight for $285',
      description: 'LAX to NYC, nonstop, Delta, under $300',
      price: 285,
      originalPrice: 340,
      savings: 55,
      confidence: 'high'
    },
    {
      type: 'flexible-match',
      title: '⚡ PRICE BREAK: $275 flight available',
      description: 'Different airline but meets budget',
      price: 275,
      originalPrice: 340,
      savings: 65,
      differences: ['Different airline (American instead of Delta)', '1 stop instead of nonstop'],
      confidence: 'medium'
    }
  ];

  const historicalData: HistoricalPriceData[] = [
    { date: '2024-01-01', price: 400, trend: 'rising' },
    { date: '2024-01-15', price: 380, trend: 'falling' },
    { date: '2024-02-01', price: 360, trend: 'falling' },
    { date: '2024-02-15', price: 340, trend: 'falling' },
    { date: '2024-03-01', price: 320, trend: 'falling' }
  ];

  const steps = [
    { id: 1, title: 'Route & Dates', icon: MapPin },
    { id: 2, title: 'Flight Preferences', icon: Plane },
    { id: 3, title: 'Price Settings', icon: DollarSign },
    { id: 4, title: 'Alert Preferences', icon: Bell }
  ];

  const updateFilter = (updates: Partial<FlightFilter>) => {
    setFilter(prev => ({ ...prev, ...updates }));
  };

  const validateStep = (step: number): boolean => {
    const newErrors: ValidationError[] = [];

    switch (step) {
      case 1:
        if (!filter.origin) newErrors.push({ field: 'origin', message: 'Origin airport is required' });
        if (!filter.destination) newErrors.push({ field: 'destination', message: 'Destination airport is required' });
        if (!filter.departureDate) newErrors.push({ field: 'departureDate', message: 'Departure date is required' });
        if (filter.tripType === 'round-trip' && !filter.returnDate) {
          newErrors.push({ field: 'returnDate', message: 'Return date is required for round-trip' });
        }
        break;
      case 2:
        if (filter.passengers.adults === 0) newErrors.push({ field: 'passengers', message: 'At least one adult passenger is required' });
        break;
      case 3:
        if (filter.targetPrice <= 0) newErrors.push({ field: 'targetPrice', message: 'Target price must be greater than 0' });
        if (filter.budgetRange.min >= filter.budgetRange.max) {
          newErrors.push({ field: 'budgetRange', message: 'Minimum budget must be less than maximum budget' });
        }
        break;
      case 4:
        if (!filter.filterName.trim()) newErrors.push({ field: 'filterName', message: 'Filter name is required' });
        if (!Object.values(filter.notificationMethods).some(Boolean)) {
          newErrors.push({ field: 'notificationMethods', message: 'At least one notification method must be selected' });
        }
        break;
    }

    setErrors(newErrors);
    return newErrors.length === 0;
  };

  const nextStep = () => {
    if (validateStep(currentStep)) {
      setCurrentStep(prev => Math.min(prev + 1, 4));
    }
  };

  const prevStep = () => {
    setCurrentStep(prev => Math.max(prev - 1, 1));
  };

  const handleSaveFilter = () => {
    if (validateStep(4) && onSaveFilter) {
      onSaveFilter(filter);
    }
  };

  const handlePreviewAlert = () => {
    if (onPreviewAlert) {
      onPreviewAlert(filter);
    }
  };

  const handleTestAlert = () => {
    if (onTestAlert) {
      onTestAlert(filter);
    }
  };

  const copyFromTemplate = (template: FilterTemplate) => {
    setFilter(prev => ({ ...prev, ...template.filter }));
    setCurrentStep(1);
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

  return (
    <div className="max-w-6xl mx-auto p-6 bg-white rounded-lg shadow-lg">
      {/* Header */}
      <div className="text-center mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">
          Flight Price Monitoring Filter
        </h1>
        <p className="text-gray-600">
          Set up intelligent flight price alerts with instant price break notifications
        </p>
      </div>

      {/* Progress Bar */}
      <div className="mb-8">
        <div className="flex items-center justify-between mb-4">
          {steps.map((step, index) => {
            const Icon = step.icon;
            const isActive = currentStep === step.id;
            const isCompleted = currentStep > step.id;
            
            return (
              <div key={step.id} className="flex items-center">
                <div className={`flex items-center justify-center w-12 h-12 rounded-full border-2 ${
                  isCompleted 
                    ? 'bg-green-500 border-green-500 text-white' 
                    : isActive 
                    ? 'bg-blue-500 border-blue-500 text-white' 
                    : 'bg-gray-200 border-gray-300 text-gray-500'
                }`}>
                  {isCompleted ? <Check className="w-6 h-6" /> : <Icon className="w-6 h-6" />}
                </div>
                <div className="ml-3">
                  <div className={`text-sm font-medium ${
                    isActive ? 'text-blue-600' : isCompleted ? 'text-green-600' : 'text-gray-500'
                  }`}>
                    {step.title}
                  </div>
                </div>
                {index < steps.length - 1 && (
                  <div className={`w-16 h-0.5 mx-4 ${
                    isCompleted ? 'bg-green-500' : 'bg-gray-300'
                  }`} />
                )}
              </div>
            );
          })}
        </div>
      </div>

      {/* Quick Actions */}
      <div className="mb-6 flex flex-wrap gap-4">
        <button
          onClick={() => setShowSummary(!showSummary)}
          className="flex items-center px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors"
        >
          <Eye className="w-4 h-4 mr-2" />
          {showSummary ? 'Hide Summary' : 'Show Summary'}
        </button>
        
        <div className="flex gap-2">
          {filterTemplates.map(template => (
            <button
              key={template.id}
              onClick={() => copyFromTemplate(template)}
              className="flex items-center px-3 py-2 bg-blue-50 text-blue-700 rounded-lg hover:bg-blue-100 transition-colors text-sm"
            >
              <Copy className="w-3 h-3 mr-1" />
              {template.name}
            </button>
          ))}
        </div>
      </div>

      {/* Filter Builder */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Main Form */}
        <div className="lg:col-span-2">
          {currentStep === 1 && (
            <Step1RouteDates 
              filter={filter} 
              updateFilter={updateFilter} 
              errors={errors}
            />
          )}
          
          {currentStep === 2 && (
            <Step2FlightPreferences 
              filter={filter} 
              updateFilter={updateFilter} 
              errors={errors}
            />
          )}
          
          {currentStep === 3 && (
            <Step3PriceSettings 
              filter={filter} 
              updateFilter={updateFilter} 
              errors={errors}
              priceBreakExamples={priceBreakExamples}
              historicalData={historicalData}
            />
          )}
          
          {currentStep === 4 && (
            <Step4AlertPreferences 
              filter={filter} 
              updateFilter={updateFilter} 
              errors={errors}
            />
          )}

          {/* Navigation */}
          <div className="flex justify-between mt-8">
            <button
              onClick={prevStep}
              disabled={currentStep === 1}
              className="flex items-center px-6 py-3 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <ArrowLeft className="w-4 h-4 mr-2" />
              Previous
            </button>
            
            {currentStep < 4 ? (
              <button
                onClick={nextStep}
                className="flex items-center px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
              >
                Next
                <ArrowRight className="w-4 h-4 ml-2" />
              </button>
            ) : (
              <div className="flex gap-3">
                <button
                  onClick={handlePreviewAlert}
                  className="flex items-center px-4 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
                >
                  <Eye className="w-4 h-4 mr-2" />
                  Preview Alert
                </button>
                <button
                  onClick={handleTestAlert}
                  className="flex items-center px-4 py-3 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
                >
                  <Play className="w-4 h-4 mr-2" />
                  Test Alert
                </button>
                <button
                  onClick={handleSaveFilter}
                  className="flex items-center px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                >
                  <Save className="w-4 h-4 mr-2" />
                  Save Filter
                </button>
              </div>
            )}
          </div>
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Popular Routes */}
          <div className="bg-gray-50 p-4 rounded-lg">
            <h3 className="font-semibold text-gray-900 mb-3 flex items-center">
              <Star className="w-4 h-4 mr-2" />
              Popular Routes
            </h3>
            <div className="space-y-3">
              {popularRoutes.map((route, index) => (
                <button
                  key={index}
                  onClick={() => {
                    updateFilter({ 
                      origin: route.origin, 
                      destination: route.destination 
                    });
                    setCurrentStep(1);
                  }}
                  className="w-full text-left p-3 bg-white rounded-lg border hover:border-blue-300 transition-colors"
                >
                  <div className="flex justify-between items-center mb-1">
                    <span className="font-medium text-sm">
                      {route.origin.code} → {route.destination.code}
                    </span>
                    <span className="text-xs text-gray-500">
                      {route.priceTrend === 'falling' ? (
                        <TrendingDown className="w-3 h-3 text-green-600" />
                      ) : route.priceTrend === 'rising' ? (
                        <TrendingUp className="w-3 h-3 text-red-600" />
                      ) : (
                        <Minus className="w-3 h-3 text-gray-400" />
                      )}
                    </span>
                  </div>
                  <div className="text-xs text-gray-600">
                    From ${route.bestPrice} (avg: ${route.averagePrice})
                  </div>
                </button>
              ))}
            </div>
          </div>

          {/* Price Break Examples */}
          <div className="bg-gray-50 p-4 rounded-lg">
            <h3 className="font-semibold text-gray-900 mb-3 flex items-center">
              <Zap className="w-4 h-4 mr-2" />
              Price Break Examples
            </h3>
            <div className="space-y-3">
              {priceBreakExamples.map((example, index) => (
                <div key={index} className="p-3 bg-white rounded-lg border">
                  <div className="font-medium text-sm mb-1">{example.title}</div>
                  <div className="text-xs text-gray-600 mb-2">{example.description}</div>
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

          {/* Estimated Results */}
          <div className="bg-blue-50 p-4 rounded-lg">
            <h3 className="font-semibold text-blue-900 mb-3">Estimated Results</h3>
            <div className="text-center">
              <div className="text-2xl font-bold text-blue-600 mb-1">24-48</div>
              <div className="text-sm text-blue-700">flights match your criteria</div>
              <div className="text-xs text-blue-600 mt-2">
                Based on current market data
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Summary Modal */}
      {showSummary && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg max-w-2xl w-full max-h-[80vh] overflow-y-auto">
            <div className="p-6">
              <div className="flex justify-between items-center mb-4">
                <h2 className="text-xl font-semibold">Filter Summary</h2>
                <button
                  onClick={() => setShowSummary(false)}
                  className="text-gray-400 hover:text-gray-600"
                >
                  ×
                </button>
              </div>
              <FilterSummary filter={filter} />
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default FlightPriceFilter;
