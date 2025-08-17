export interface Airport {
  code: string;
  name: string;
  city: string;
  country: string;
}

export interface FlightFilter {
  // Step 1: Route & Dates
  origin: Airport | null;
  destination: Airport | null;
  tripType: 'one-way' | 'round-trip' | 'multi-city';
  departureDate: Date | null;
  returnDate: Date | null;
  flexibleDates: boolean;
  dateFlexibility: number; // +/- days
  
  // Step 2: Flight Preferences
  cabinClass: 'economy' | 'premium-economy' | 'business' | 'first';
  passengers: {
    adults: number;
    children: number;
    infants: number;
  };
  airlinePreferences: string[];
  maxStops: 'nonstop' | '1-stop' | '2+';
  preferredTimes: {
    departure: ('morning' | 'afternoon' | 'evening' | 'red-eye')[];
    arrival: ('morning' | 'afternoon' | 'evening' | 'red-eye')[];
  };
  
  // Step 3: Price Settings
  targetPrice: number;
  currency: string;
  instantPriceBreakAlerts: {
    enabled: boolean;
    type: 'exact-match' | 'flexible-match';
    flexibilityOptions: {
      airline: boolean;
      stops: boolean;
      times: boolean;
      dates: boolean;
    };
  };
  priceDropPercentage: number;
  budgetRange: {
    min: number;
    max: number;
  };
  priceBreakConfidence: 'low' | 'medium' | 'high';
  
  // Step 4: Alert Preferences
  monitorFrequency: 'real-time' | 'hourly' | 'daily' | 'weekly';
  alertUrgency: 'patient' | 'moderate' | 'urgent';
  instantAlertPriority: 'normal' | 'high' | 'critical';
  alertDetailLevel: 'exact-matches-only' | 'include-near-matches';
  notificationMethods: {
    email: boolean;
    sms: boolean;
    push: boolean;
    browser: boolean;
  };
  
  // Metadata
  filterName: string;
  description: string;
  createdAt: Date;
  isActive: boolean;
}

export interface PriceBreakExample {
  type: 'exact-match' | 'flexible-match';
  title: string;
  description: string;
  price: number;
  originalPrice: number;
  savings: number;
  differences?: string[];
  confidence: 'low' | 'medium' | 'high';
}

export interface HistoricalPriceData {
  date: string;
  price: number;
  trend: 'rising' | 'falling' | 'stable';
}

export interface PopularRoute {
  origin: Airport;
  destination: Airport;
  averagePrice: number;
  bestPrice: number;
  priceTrend: 'rising' | 'falling' | 'stable';
}

export interface FilterTemplate {
  id: string;
  name: string;
  description: string;
  category: 'business' | 'vacation' | 'last-minute' | 'budget' | 'luxury';
  filter: Partial<FlightFilter>;
}

export interface ValidationError {
  field: string;
  message: string;
}

export interface FilterValidationResult {
  isValid: boolean;
  errors: ValidationError[];
}
