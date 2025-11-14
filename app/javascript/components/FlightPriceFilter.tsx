import React, { useMemo, useState } from 'react';
import {
  Plane,
  MapPin,
  Users,
  DollarSign,
  Bell,
  ArrowRight,
  ArrowLeft,
  Check,
  Search,
} from "lucide-react";
import { 
  FlightFilter, 
  Airport, 
  ValidationError 
} from '../types/flight-filter';
import ResponsiveAirportAutocomplete from './ResponsiveAirportAutocomplete';
import Step1RouteDates from './steps/Step1RouteDates';
import Step2FlightPreferences from './steps/Step2FlightPreferences';
import Step3PriceSettings from './steps/Step3PriceSettings';
import Step4AlertPreferences from './steps/Step4AlertPreferences';
import AlertPreviewModal from './AlertPreviewModal';
import {
  FlightPriceCalendarDate,
  FlightPriceCalendarMode,
  FlightPriceCalendarSelection,
} from './FlightPriceCalendar';

interface FlightPriceFilterProps {
  onSaveFilter?: (filter: FlightFilter) => void;
  onPreviewAlert?: (filter: FlightFilter) => void;
  onTestAlert?: (filter: FlightFilter) => void;
  initialFilter?: Partial<FlightFilter>;
  calendarDates?: FlightPriceCalendarDate[];
  calendarPriceRange?: { min: number; max: number };
  onCalendarApply?: (
    selection: FlightPriceCalendarSelection & { mode: FlightPriceCalendarMode },
  ) => void;
}

const brandGradient = "from-[#8B5CF6] via-[#7C3AED] to-[#6B21A8]";

const generateSeededCalendarData = (
  seedKey: string,
  totalDays = 90,
): FlightPriceCalendarDate[] => {
  const normalizedSeed = seedKey
    .toUpperCase()
    .split("")
    .reduce((acc, char, index) => acc + char.charCodeAt(0) * (index + 1), 0);

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  return Array.from({ length: totalDays }, (_, index) => {
    const currentDate = new Date(today);
    currentDate.setDate(today.getDate() + index);

    const base = 140 + (normalizedSeed % 70);
    const seasonal = Math.sin((index + normalizedSeed / 10) / 4) * 35;
    const weekendBoost = [5, 6].includes(currentDate.getDay()) ? 20 : 0;
    const trend = ((index % 30) - 15) * 1.2;
    const noise = ((normalizedSeed >> (index % 8)) & 1 ? 10 : -10);
    const price = Math.max(
      68,
      Math.round(base + seasonal + weekendBoost + trend + noise),
    );

    return {
      date: currentDate,
      price,
    };
  });
};

const FlightPriceFilter: React.FC<FlightPriceFilterProps> = ({
  onSaveFilter,
  onPreviewAlert,
  onTestAlert,
  initialFilter,
  calendarDates,
  calendarPriceRange,
  onCalendarApply,
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
    isActive: true,
    ...initialFilter
  });

  const [errors, setErrors] = useState<ValidationError[]>([]);
  const [showPreviewModal, setShowPreviewModal] = useState(false);

  const seededCalendarData = useMemo(() => {
    if (calendarDates && calendarDates.length) {
      return calendarDates;
    }

    const seedKey = `${filter.origin?.iata_code ?? "ANY"}-${
      filter.destination?.iata_code ?? "ROUTE"
    }`;
    return generateSeededCalendarData(seedKey);
  }, [
    calendarDates,
    filter.destination?.iata_code,
    filter.origin?.iata_code,
  ]);

  const seededPriceRange = useMemo(() => {
    if (calendarPriceRange) {
      return calendarPriceRange;
    }
    if (!seededCalendarData.length) {
      return undefined;
    }
    const prices = seededCalendarData.map((item) => item.price);
    return {
      min: Math.min(...prices),
      max: Math.max(...prices),
    };
  }, [calendarPriceRange, seededCalendarData]);

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
        if (filter.passengers?.adults === 0) newErrors.push({ field: 'passengers', message: 'At least one adult passenger is required' });
        break;
      case 3:
        if (filter.targetPrice <= 0) newErrors.push({ field: 'targetPrice', message: 'Target price must be greater than 0' });
        if (filter.budgetRange?.min >= filter.budgetRange?.max) {
          newErrors.push({ field: 'budgetRange', message: 'Minimum budget must be less than maximum budget' });
        }
        break;
      case 4:
        if (!filter.filterName?.trim()) newErrors.push({ field: 'filterName', message: 'Filter name is required' });
        if (!Object.values(filter.notificationMethods || {}).some(Boolean)) {
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


  const getError = (field: string) => {
    return errors.find(error => error.field === field)?.message;
  };

  return (
    <div className="relative isolate flex min-h-screen w-full justify-center overflow-hidden bg-gradient-to-br from-[#8B5CF6] via-[#7C3AED] to-[#6B21A8] px-6 py-12">
      <div className="pointer-events-none absolute inset-0 -z-10">
        <div className="absolute -left-24 top-24 h-64 w-64 rounded-full bg-white/10 blur-3xl" />
        <div className="absolute -right-16 bottom-16 h-72 w-72 rounded-full bg-[#06B6D4]/20 blur-3xl" />
      </div>
      <div className="w-full max-w-6xl">
      {/* Header */}
      <div className="mb-12 text-center text-white">
        <h1 className="text-4xl font-bold md:text-5xl">
          Create a Flight Price Alert
        </h1>
        <p className="mx-auto mt-4 max-w-2xl text-lg text-white/80">
          Set up AI-powered monitoring to capture the perfect fare in our signature PriceBreak
          experience.
        </p>
      </div>

      {/* Step Indicator */}
      <div className="mb-12">
        <div className="flex items-center justify-center space-x-2 sm:space-x-4">
          {steps.map((step, index) => {
            const isActive = currentStep === step.id;
            const isCompleted = currentStep > step.id;
            
            return (
              <React.Fragment key={step.id}>
                <div className="flex flex-col items-center">
                  <div
                    className={`flex h-10 w-10 items-center justify-center rounded-full text-sm font-semibold transition-all duration-300 sm:h-12 sm:w-12 ${
                      isActive
                        ? 'bg-gradient-to-br from-[#8B5CF6] via-[#7C3AED] to-[#6B21A8] text-white shadow-xl shadow-[#4C1D951f] scale-110'
                        : isCompleted
                          ? 'bg-[#C4B5FD] text-[#4C1D95] shadow-inner shadow-white/30'
                          : 'border border-white/40 bg-white/20 text-white/70 backdrop-blur-sm'
                    }`}
                  >
                    {isCompleted ? <Check className="w-5 h-5 sm:w-6 sm:h-6" /> : step.id}
                  </div>
                  <span
                    className={`mt-2 hidden text-xs font-medium sm:block sm:text-sm ${
                      isActive
                        ? 'text-white'
                        : isCompleted
                          ? 'text-white/80'
                          : 'text-white/60'
                    }`}
                  >
                    {step.title}
                  </span>
                </div>
                {index < steps.length - 1 && (
                  <div
                    className={`mx-2 h-[2px] flex-1 rounded-full transition-all duration-300 sm:mx-4 ${
                      isCompleted ? 'bg-white/70' : 'bg-white/25'
                    }`}
                    style={{ minWidth: '40px', maxWidth: '80px' }}
                  />
                )}
              </React.Fragment>
            );
          })}
        </div>
      </div>

      {/* Main Form Card */}
      <div className="relative overflow-hidden rounded-[32px] border border-white/20 bg-white/10 p-[1px] shadow-[0_35px_80px_rgba(43,17,89,0.35)]">
        <div className="rounded-[32px] bg-white/90">
        {/* Step Content */}
        <div className="p-6 sm:p-8 lg:p-10">
          {currentStep === 1 && (
            <Step1RouteDates 
              filter={filter} 
              updateFilter={updateFilter} 
              errors={errors}
              calendarDates={seededCalendarData}
              calendarPriceRange={seededPriceRange}
              onCalendarApply={onCalendarApply}
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
              priceBreakExamples={[]}
              historicalData={[]}
            />
          )}
          
          {currentStep === 4 && (
            <Step4AlertPreferences 
              filter={filter} 
              updateFilter={updateFilter} 
              errors={errors}
            />
          )}
        </div>

        {/* Navigation Footer */}
        <div className="border-t border-white/40 bg-white/60 px-6 py-6 sm:px-8 lg:px-10">
          <div className="flex items-center justify-between">
            <button
              onClick={prevStep}
              disabled={currentStep === 1}
              className="flex items-center rounded-xl border-2 border-[#E9D5FF] bg-white/80 px-6 py-3 font-medium text-[#4C1D95] transition-all hover:border-[#C4B5FD] hover:bg-white disabled:cursor-not-allowed disabled:opacity-40"
            >
              <ArrowLeft className="w-4 h-4 mr-2" />
              Previous
            </button>
            
            {currentStep < 4 ? (
              <button
                onClick={nextStep}
                className="flex items-center rounded-xl bg-gradient-to-r from-[#8B5CF6] via-[#7C3AED] to-[#6B21A8] px-8 py-3 text-base font-semibold text-white shadow-[0_20px_45px_rgba(91,33,182,0.45)] transition-all hover:scale-[1.01] hover:shadow-[0_24px_55px_rgba(91,33,182,0.5)]"
              >
                Continue
                <ArrowRight className="w-5 h-5 ml-2" />
              </button>
            ) : (
              <div className="flex items-center space-x-3">
                <button
                  onClick={() => {
                    if (onPreviewAlert) {
                      onPreviewAlert(filter);
                      setShowPreviewModal(true);
                    }
                  }}
                  className="flex items-center rounded-xl bg-white/80 px-6 py-3 text-base font-medium text-[#4C1D95] transition-all hover:bg-white"
                >
                  Preview Alert
                </button>
                <button
                  onClick={() => {
                    if (onTestAlert) {
                      onTestAlert(filter);
                    }
                  }}
                  className="flex items-center rounded-xl bg-[#DDD6FE] px-6 py-3 text-base font-medium text-[#4C1D95] transition-all hover:bg-[#C4B5FD]"
                >
                  Test Alert
                </button>
                <button
                  onClick={handleSaveFilter}
                  className="flex items-center rounded-xl bg-gradient-to-r from-[#06B6D4] via-[#0ea5e9] to-[#164e63] px-8 py-3 text-base font-semibold text-white shadow-[0_20px_45px_rgba(14,165,233,0.35)] transition-all hover:scale-[1.01] hover:shadow-[0_24px_55px_rgba(8,145,178,0.45)]"
                >
                  <Search className="w-5 h-5 mr-2" />
                  Create Price Alert
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
      </div>
      </div>

      {/* Filter Summary - Always Visible */}
      <div className="mt-10 rounded-3xl border border-white/20 bg-white/10 p-6 text-white backdrop-blur-lg">
        <h3 className="mb-4 flex items-center text-lg font-semibold">
          <Plane className="w-5 h-5 mr-2 text-[#06B6D4]" />
          Filter Summary
        </h3>
        <div className="grid grid-cols-1 gap-4 text-sm sm:grid-cols-2 lg:grid-cols-3">
          <div className="flex items-center">
            <span className="mr-2 font-medium text-white/70">From:</span>
            <span className="font-semibold">
              {filter.origin ? `${filter.origin.iata_code} - ${filter.origin.city}` : 'Not selected'}
            </span>
          </div>
          <div className="flex items-center">
            <span className="mr-2 font-medium text-white/70">To:</span>
            <span className="font-semibold">
              {filter.destination ? `${filter.destination.iata_code} - ${filter.destination.city}` : 'Not selected'}
            </span>
          </div>
          <div className="flex items-center">
            <span className="mr-2 font-medium text-white/70">Trip:</span>
            <span className="capitalize">
              {filter.tripType?.replace('-', ' ')}
            </span>
          </div>
          <div className="flex items-center">
            <span className="mr-2 font-medium text-white/70">Cabin:</span>
            <span className="capitalize">{filter.cabinClass?.replace('-', ' ')}</span>
          </div>
          <div className="flex items-center">
            <span className="mr-2 font-medium text-white/70">Passengers:</span>
            <span className="font-semibold">
              {(filter.passengers?.adults || 0) + (filter.passengers?.children || 0) + (filter.passengers?.infants || 0)}
            </span>
          </div>
          <div className="flex items-center">
            <span className="mr-2 font-medium text-white/70">Target Price:</span>
            <span className="font-semibold">
              ${filter.targetPrice ? filter.targetPrice : 0}
            </span>
          </div>
        </div>
      </div>

      {/* Alert Preview Modal */}
      <AlertPreviewModal
        filter={filter}
        isOpen={showPreviewModal}
        onClose={() => setShowPreviewModal(false)}
      />
    </div>
  );
};

export default FlightPriceFilter;
