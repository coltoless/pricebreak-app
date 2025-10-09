import React, { useState, useEffect } from 'react';
import { 
  Plane, 
  MapPin, 
  Calendar, 
  Users, 
  ChevronDown,
  Search,
  Filter,
  TrendingUp,
  TrendingDown,
  AlertCircle,
  CheckCircle,
  Clock,
  DollarSign,
  Zap,
  Bell,
  Settings,
  Heart,
  Share2,
  Star,
  Eye,
  BarChart3,
  Target,
  Shield,
  Info,
  ArrowRight,
  ArrowLeft,
  X,
  Plus,
  Minus
} from 'lucide-react';
import { FlightFilter, Airport } from '../types/flight-filter';
import FlightFilterSidebar from './FlightFilterSidebar';
import PriceChart from './PriceChart';
import AlertManager from './AlertManager';
import ResponsiveAirportAutocomplete from './ResponsiveAirportAutocomplete';

interface FlightResult {
  id: string;
  airline: string;
  airlineCode: string;
  departure: {
    time: string;
    airport: string;
    terminal?: string;
  };
  arrival: {
    time: string;
    airport: string;
    terminal?: string;
  };
  duration: string;
  stops: number;
  price: number;
  originalPrice?: number;
  currency: string;
  cabinClass: string;
  aircraft?: string;
  baggage?: string;
  refundable: boolean;
  priceTrend: 'up' | 'down' | 'stable';
  priceDrop?: number;
  dealScore?: number;
  bookingUrl: string;
}

interface FlightSearchInterfaceProps {
  onFilterChange?: (filter: FlightFilter) => void;
  onSaveFilter?: (filter: FlightFilter) => void;
  className?: string;
}

const FlightSearchInterface: React.FC<FlightSearchInterfaceProps> = ({
  onFilterChange,
  onSaveFilter,
  className = ""
}) => {
  const [showFilters, setShowFilters] = useState(false);
  const [isMobile, setIsMobile] = useState(false);
  const [originSearch, setOriginSearch] = useState('');
  const [destinationSearch, setDestinationSearch] = useState('');
  const [showTravelersModal, setShowTravelersModal] = useState(false);
  const [currentFilter, setCurrentFilter] = useState<FlightFilter>({
    // Default filter state
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

  const [searchResults, setSearchResults] = useState<FlightResult[]>([]);
  const [loading, setLoading] = useState(false);
  const [showPriceChart, setShowPriceChart] = useState(false);
  const [showAlertManager, setShowAlertManager] = useState(false);
  const [sortBy, setSortBy] = useState<'price' | 'duration' | 'departure' | 'arrival'>('price');
  const [viewMode, setViewMode] = useState<'list' | 'grid'>('list');

  // Mock flight results
  const mockResults: FlightResult[] = [
    {
      id: '1',
      airline: 'Delta Air Lines',
      airlineCode: 'DL',
      departure: { time: '08:30', airport: 'SEA', terminal: 'A' },
      arrival: { time: '14:45', airport: 'LAX', terminal: '2' },
      duration: '6h 15m',
      stops: 0,
      price: 456,
      originalPrice: 520,
      currency: 'USD',
      cabinClass: 'Economy',
      aircraft: 'Boeing 737-900',
      baggage: '1 carry-on + 1 personal item',
      refundable: false,
      priceTrend: 'down',
      priceDrop: 12,
      dealScore: 85,
      bookingUrl: '#'
    },
    {
      id: '2',
      airline: 'American Airlines',
      airlineCode: 'AA',
      departure: { time: '12:15', airport: 'SEA', terminal: 'B' },
      arrival: { time: '18:30', airport: 'LAX', terminal: '4' },
      duration: '6h 15m',
      stops: 0,
      price: 489,
      currency: 'USD',
      cabinClass: 'Economy',
      aircraft: 'Airbus A321',
      baggage: '1 carry-on + 1 personal item',
      refundable: true,
      priceTrend: 'stable',
      dealScore: 72,
      bookingUrl: '#'
    },
    {
      id: '3',
      airline: 'United Airlines',
      airlineCode: 'UA',
      departure: { time: '15:45', airport: 'SEA', terminal: 'A' },
      arrival: { time: '22:00', airport: 'LAX', terminal: '7' },
      duration: '6h 15m',
      stops: 0,
      price: 512,
      currency: 'USD',
      cabinClass: 'Economy',
      aircraft: 'Boeing 737-800',
      baggage: '1 carry-on + 1 personal item',
      refundable: false,
      priceTrend: 'up',
      dealScore: 68,
      bookingUrl: '#'
    }
  ];

  useEffect(() => {
    setSearchResults(mockResults);
    
    // Check if mobile
    const checkMobile = () => {
      setIsMobile(window.innerWidth < 768);
    };
    
    checkMobile();
    window.addEventListener('resize', checkMobile);
    
    return () => window.removeEventListener('resize', checkMobile);
  }, []);

  const updateFilter = (updates: Partial<FlightFilter>) => {
    const newFilter = { ...currentFilter, ...updates };
    setCurrentFilter(newFilter);
    onFilterChange?.(newFilter);
  };

  // Initialize search values when airports are selected
  useEffect(() => {
    if (currentFilter.origin) {
      setOriginSearch(`${currentFilter.origin.iata_code} - ${currentFilter.origin.city}`);
    }
    if (currentFilter.destination) {
      setDestinationSearch(`${currentFilter.destination.iata_code} - ${currentFilter.destination.city}`);
    }
  }, [currentFilter.origin, currentFilter.destination]);

  const handleOriginSelect = (airport: Airport | null) => {
    updateFilter({ origin: airport });
  };

  const handleDestinationSelect = (airport: Airport | null) => {
    updateFilter({ destination: airport });
  };

  const handleSearch = async () => {
    setLoading(true);
    // Simulate API call
    setTimeout(() => {
      setLoading(false);
      // In real implementation, this would fetch from your API
    }, 2000);
  };

  const formatPrice = (price: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: currentFilter.currency || 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(price);
  };

  const formatDate = (date: Date | null) => {
    if (!date) return 'Select date';
    return date.toLocaleDateString('en-US', { 
      weekday: 'short', 
      month: 'short', 
      day: 'numeric' 
    });
  };

  const getPassengerText = () => {
    const { adults, children, infants } = currentFilter.passengers;
    let text = `${adults} Adult${adults > 1 ? 's' : ''}`;
    if (children > 0) text += `, ${children} Child${children > 1 ? 'ren' : ''}`;
    if (infants > 0) text += `, ${infants} Infant${infants > 1 ? 's' : ''}`;
    return text;
  };

  const sortedResults = [...searchResults].sort((a, b) => {
    switch (sortBy) {
      case 'price':
        return a.price - b.price;
      case 'duration':
        return a.duration.localeCompare(b.duration);
      case 'departure':
        return a.departure.time.localeCompare(b.departure.time);
      case 'arrival':
        return a.arrival.time.localeCompare(b.arrival.time);
      default:
        return 0;
    }
  });

  return (
    <div className={`min-h-screen bg-gray-50 ${className}`}>
      {/* Header - Skyscanner Style */}
      <header className="bg-gradient-to-r from-blue-600 to-blue-700 text-white shadow-lg">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            {/* Logo */}
            <div className="flex items-center">
              <div className="flex-shrink-0 flex items-center">
                <div className="w-8 h-8 bg-white rounded-lg flex items-center justify-center mr-3">
                  <Plane className="w-5 h-5 text-blue-600" />
                </div>
                <h1 className="text-xl font-bold">PriceBreak</h1>
              </div>
            </div>

            {/* Navigation */}
            <nav className="hidden md:flex items-center space-x-8">
              <a href="#" className="text-blue-100 hover:text-white transition-colors">Help</a>
              <a href="#" className="text-blue-100 hover:text-white transition-colors">Login</a>
            </nav>

            {/* Mobile menu button */}
            <div className="md:hidden">
              <button className="text-blue-100 hover:text-white">
                <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
                </svg>
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Main Navigation Tabs */}
      <div className="bg-white border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex space-x-8">
            {[
              { id: 'flights', label: 'Flights', icon: Plane, active: true },
              { id: 'hotels', label: 'Hotels', icon: null },
              { id: 'cars', label: 'Car rental', icon: null }
            ].map(({ id, label, icon: Icon, active }) => (
              <button
                key={id}
                className={`flex items-center py-4 px-1 border-b-2 font-medium text-sm ${
                  active
                    ? 'border-blue-500 text-blue-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                {Icon && <Icon className="w-4 h-4 mr-2" />}
                {label}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Hero Section */}
      <div className="bg-gradient-to-r from-blue-600 to-blue-700 text-white py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h2 className="text-3xl md:text-4xl font-bold mb-4">
            Millions of cheap flights. One simple search.
          </h2>
          <p className="text-blue-100 text-lg">
            Find the best deals with PriceBreak's intelligent price monitoring
          </p>
        </div>
      </div>

      {/* Search Form - Skyscanner Style */}
      <div className="bg-white shadow-lg -mt-8 relative z-10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="py-6">
            {/* Trip Type */}
            <div className="mb-6">
              <div className="flex rounded-lg bg-gray-100 p-1 w-fit">
                {[
                  { key: 'round-trip', label: 'Roundtrip' },
                  { key: 'one-way', label: 'One-way' },
                  { key: 'multi-city', label: 'Multi-city' }
                ].map(({ key, label }) => (
                  <button
                    key={key}
                    onClick={() => updateFilter({ tripType: key as any })}
                    className={`px-4 py-2 text-sm font-medium rounded-md transition-colors ${
                      currentFilter.tripType === key
                        ? 'bg-white text-blue-600 shadow-sm'
                        : 'text-gray-600 hover:text-gray-800'
                    }`}
                  >
                    {label}
                  </button>
                ))}
              </div>
            </div>

            {/* Search Fields */}
            <div className="grid grid-cols-1 md:grid-cols-5 gap-4 items-end">
              {/* From */}
              <div className="relative">
                <ResponsiveAirportAutocomplete
                  value={originSearch}
                  onChange={setOriginSearch}
                  onSelect={handleOriginSelect}
                  placeholder="Country, city or airport"
                  selectedAirport={currentFilter.origin}
                  showPopularAirports={true}
                />
              </div>

              {/* Swap Button */}
              <div className="flex justify-center">
                <button 
                  className="w-10 h-10 bg-gray-200 hover:bg-gray-300 rounded-full flex items-center justify-center transition-colors"
                  onClick={() => {
                    const temp = currentFilter.origin;
                    updateFilter({ 
                      origin: currentFilter.destination, 
                      destination: temp 
                    });
                  }}
                >
                  <ArrowRight className="w-4 h-4 text-gray-600" />
                </button>
              </div>

              {/* To */}
              <div className="relative">
                <ResponsiveAirportAutocomplete
                  value={destinationSearch}
                  onChange={setDestinationSearch}
                  onSelect={handleDestinationSelect}
                  placeholder="Country, city or airport"
                  selectedAirport={currentFilter.destination}
                  showPopularAirports={true}
                />
              </div>

              {/* Depart */}
              <div className="relative">
                <label className="block text-sm font-medium text-gray-700 mb-1">Depart</label>
                <div className="relative">
                  <input
                    type="date"
                    value={currentFilter.departureDate ? currentFilter.departureDate.toISOString().split('T')[0] : ''}
                    onChange={(e) => {
                      const date = e.target.value ? new Date(e.target.value) : null;
                      updateFilter({ departureDate: date });
                    }}
                    min={new Date().toISOString().split('T')[0]}
                    className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                  <Calendar className="absolute right-3 top-3.5 w-5 h-5 text-gray-400 pointer-events-none" />
                </div>
              </div>

              {/* Return */}
              {currentFilter.tripType === 'round-trip' && (
                <div className="relative">
                  <label className="block text-sm font-medium text-gray-700 mb-1">Return</label>
                  <div className="relative">
                    <input
                      type="date"
                      value={currentFilter.returnDate ? currentFilter.returnDate.toISOString().split('T')[0] : ''}
                      onChange={(e) => {
                        const date = e.target.value ? new Date(e.target.value) : null;
                        updateFilter({ returnDate: date });
                      }}
                      min={currentFilter.departureDate ? currentFilter.departureDate.toISOString().split('T')[0] : new Date().toISOString().split('T')[0]}
                      className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    />
                    <Calendar className="absolute right-3 top-3.5 w-5 h-5 text-gray-400 pointer-events-none" />
                  </div>
                </div>
              )}
            </div>

            {/* Secondary Row */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mt-4">
              {/* Travelers */}
              <div className="relative">
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Travelers and cabin class
                </label>
                <div className="relative">
                  <input
                    type="text"
                    value={`${currentFilter.passengers.adults} Adult${currentFilter.passengers.adults > 1 ? 's' : ''}${currentFilter.passengers.children > 0 ? `, ${currentFilter.passengers.children} Child${currentFilter.passengers.children > 1 ? 'ren' : ''}` : ''}${currentFilter.passengers.infants > 0 ? `, ${currentFilter.passengers.infants} Infant${currentFilter.passengers.infants > 1 ? 's' : ''}` : ''}, ${currentFilter.cabinClass}`}
                    className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent cursor-pointer"
                    onClick={() => setShowTravelersModal(true)}
                    readOnly
                  />
                  <Users className="absolute right-3 top-3.5 w-5 h-5 text-gray-400 pointer-events-none" />
                </div>
              </div>

              {/* Search Button */}
              <div className="md:col-span-3 flex items-end">
                <button
                  onClick={handleSearch}
                  className="w-full md:w-auto bg-blue-600 text-white px-8 py-3 rounded-lg font-medium hover:bg-blue-700 transition-colors flex items-center justify-center gap-2"
                >
                  <Search className="w-5 h-5" />
                  Search
                </button>
              </div>
            </div>

            {/* Options */}
            <div className="flex flex-wrap gap-4 mt-4">
              <label className="flex items-center">
                <input type="checkbox" className="rounded border-gray-300 text-blue-600 focus:ring-blue-500" />
                <span className="ml-2 text-sm text-gray-700">Add nearby airports</span>
              </label>
              <label className="flex items-center">
                <input type="checkbox" className="rounded border-gray-300 text-blue-600 focus:ring-blue-500" />
                <span className="ml-2 text-sm text-gray-700">Direct flights only</span>
              </label>
              <label className="flex items-center">
                <input type="checkbox" className="rounded border-gray-300 text-blue-600 focus:ring-blue-500" />
                <span className="ml-2 text-sm text-gray-700">Add a hotel</span>
              </label>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="flex gap-8 relative">
          {/* Mobile Overlay */}
          {isMobile && showFilters && (
            <div 
              className="fixed inset-0 bg-black bg-opacity-50 z-40"
              onClick={() => setShowFilters(false)}
            />
          )}
          
          {/* Filter Sidebar */}
          <div className={`
            ${isMobile 
              ? `fixed top-0 left-0 bottom-0 z-50 bg-white transform transition-transform duration-300 ${
                  showFilters ? 'translate-x-0' : '-translate-x-full'
                }`
              : `transition-all duration-300 ${showFilters ? 'w-80' : 'w-0 overflow-hidden'}`
            }
          `}>
            <FlightFilterSidebar
              filter={currentFilter}
              updateFilter={updateFilter}
              onSaveFilter={() => {
                onSaveFilter?.(currentFilter);
                if (isMobile) setShowFilters(false);
              }}
              onTestAlert={() => setShowAlertManager(true)}
              onClose={() => setShowFilters(false)}
              className={`h-fit ${isMobile ? 'w-80' : 'sticky top-8'}`}
            />
          </div>

          {/* Results Area */}
          <div className="flex-1">
            {/* Results Header */}
            <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-4">
                  <h3 className="text-lg font-semibold text-gray-900">
                    {sortedResults.length} flights found
                  </h3>
                  <button
                    onClick={() => setShowFilters(!showFilters)}
                    className="flex items-center gap-2 px-3 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
                  >
                    <Filter className="w-4 h-4" />
                    <span className="text-sm font-medium">Filters</span>
                  </button>
                </div>
                
                <div className="flex items-center gap-4">
                  {/* Sort Options */}
                  <select
                    value={sortBy}
                    onChange={(e) => setSortBy(e.target.value as any)}
                    className="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  >
                    <option value="price">Sort by Price</option>
                    <option value="duration">Sort by Duration</option>
                    <option value="departure">Sort by Departure</option>
                    <option value="arrival">Sort by Arrival</option>
                  </select>

                  {/* View Mode */}
                  <div className="flex border border-gray-300 rounded-lg">
                    <button
                      onClick={() => setViewMode('list')}
                      className={`px-3 py-2 text-sm ${viewMode === 'list' ? 'bg-blue-600 text-white' : 'text-gray-600'}`}
                    >
                      List
                    </button>
                    <button
                      onClick={() => setViewMode('grid')}
                      className={`px-3 py-2 text-sm ${viewMode === 'grid' ? 'bg-blue-600 text-white' : 'text-gray-600'}`}
                    >
                      Grid
                    </button>
                  </div>
                </div>
              </div>

              {/* Price Intelligence Bar */}
              <div className="bg-gradient-to-r from-blue-50 to-amber-50 rounded-lg p-4 border border-blue-200">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <Zap className="w-5 h-5 text-amber-500" />
                    <div>
                      <h4 className="font-medium text-gray-900">Price Intelligence Active</h4>
                      <p className="text-sm text-gray-600">
                        Monitoring for price drops below {formatPrice(currentFilter.targetPrice || 0)}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => setShowPriceChart(true)}
                      className="flex items-center gap-2 px-3 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                    >
                      <BarChart3 className="w-4 h-4" />
                      <span className="text-sm">Price Chart</span>
                    </button>
                    <button
                      onClick={() => setShowAlertManager(true)}
                      className="flex items-center gap-2 px-3 py-2 bg-amber-600 text-white rounded-lg hover:bg-amber-700 transition-colors"
                    >
                      <Bell className="w-4 h-4" />
                      <span className="text-sm">Alerts</span>
                    </button>
                  </div>
                </div>
              </div>
            </div>

            {/* Flight Results */}
            <div className="space-y-4">
              {loading ? (
                <div className="space-y-4">
                  {[1, 2, 3].map((i) => (
                    <div key={i} className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 animate-pulse">
                      <div className="flex justify-between items-center">
                        <div className="space-y-2">
                          <div className="h-4 bg-gray-200 rounded w-32"></div>
                          <div className="h-3 bg-gray-200 rounded w-24"></div>
                        </div>
                        <div className="h-8 bg-gray-200 rounded w-20"></div>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                sortedResults.map((flight) => (
                  <div key={flight.id} className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow">
                    <div className="flex justify-between items-start">
                      {/* Flight Info */}
                      <div className="flex-1">
                        <div className="flex items-center gap-4 mb-4">
                          <div className="flex items-center gap-2">
                            <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
                              <Plane className="w-4 h-4 text-blue-600" />
                            </div>
                            <div>
                              <h4 className="font-medium text-gray-900">{flight.airline}</h4>
                              <p className="text-sm text-gray-500">{flight.aircraft}</p>
                            </div>
                          </div>
                          
                          {flight.priceTrend === 'down' && flight.priceDrop && (
                            <div className="flex items-center gap-1 bg-green-100 text-green-800 px-2 py-1 rounded-full text-xs font-medium">
                              <TrendingDown className="w-3 h-3" />
                              {flight.priceDrop}% drop
                            </div>
                          )}
                          
                          {flight.dealScore && flight.dealScore > 80 && (
                            <div className="flex items-center gap-1 bg-amber-100 text-amber-800 px-2 py-1 rounded-full text-xs font-medium">
                              <Star className="w-3 h-3" />
                              Great deal
                            </div>
                          )}
                        </div>

                        <div className="grid grid-cols-3 gap-6">
                          {/* Departure */}
                          <div>
                            <div className="text-2xl font-bold text-gray-900">{flight.departure.time}</div>
                            <div className="text-sm text-gray-600">{flight.departure.airport}</div>
                            <div className="text-xs text-gray-500">Terminal {flight.departure.terminal}</div>
                          </div>

                          {/* Duration */}
                          <div className="text-center">
                            <div className="text-sm text-gray-600 mb-1">{flight.duration}</div>
                            <div className="flex items-center justify-center">
                              <div className="flex-1 h-px bg-gray-300"></div>
                              <Plane className="w-4 h-4 text-gray-400 mx-2" />
                              <div className="flex-1 h-px bg-gray-300"></div>
                            </div>
                            <div className="text-xs text-gray-500 mt-1">
                              {flight.stops === 0 ? 'Direct' : `${flight.stops} stop${flight.stops > 1 ? 's' : ''}`}
                            </div>
                          </div>

                          {/* Arrival */}
                          <div className="text-right">
                            <div className="text-2xl font-bold text-gray-900">{flight.arrival.time}</div>
                            <div className="text-sm text-gray-600">{flight.arrival.airport}</div>
                            <div className="text-xs text-gray-500">Terminal {flight.arrival.terminal}</div>
                          </div>
                        </div>

                        <div className="mt-4 flex items-center gap-4 text-sm text-gray-600">
                          <span>{flight.baggage}</span>
                          {flight.refundable && (
                            <span className="text-green-600 font-medium">Refundable</span>
                          )}
                        </div>
                      </div>

                      {/* Price */}
                      <div className="text-right ml-6">
                        <div className="flex items-center gap-2 mb-2">
                          {flight.originalPrice && (
                            <span className="text-sm text-gray-500 line-through">
                              {formatPrice(flight.originalPrice)}
                            </span>
                          )}
                          <span className="text-2xl font-bold text-gray-900">
                            {formatPrice(flight.price)}
                          </span>
                        </div>
                        
                        <div className="space-y-2">
                          <button className="w-full bg-blue-600 text-white py-2 px-4 rounded-lg font-medium hover:bg-blue-700 transition-colors">
                            Select
                          </button>
                          
                          <div className="flex gap-2">
                            <button className="flex-1 bg-gray-100 text-gray-700 py-2 px-3 rounded-lg hover:bg-gray-200 transition-colors text-sm">
                              <Heart className="w-4 h-4 mx-auto" />
                            </button>
                            <button className="flex-1 bg-gray-100 text-gray-700 py-2 px-3 rounded-lg hover:bg-gray-200 transition-colors text-sm">
                              <Share2 className="w-4 h-4 mx-auto" />
                            </button>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Modals */}
      {showPriceChart && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg max-w-4xl w-full max-h-[80vh] overflow-hidden">
            <div className="flex items-center justify-between p-6 border-b border-gray-200">
              <h3 className="text-lg font-semibold">Price History & Trends</h3>
              <button
                onClick={() => setShowPriceChart(false)}
                className="text-gray-400 hover:text-gray-600"
              >
                <X className="w-6 h-6" />
              </button>
            </div>
            <div className="p-6">
              <PriceChart />
            </div>
          </div>
        </div>
      )}

      {showAlertManager && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg max-w-2xl w-full max-h-[80vh] overflow-hidden">
            <div className="flex items-center justify-between p-6 border-b border-gray-200">
              <h3 className="text-lg font-semibold">Alert Manager</h3>
              <button
                onClick={() => setShowAlertManager(false)}
                className="text-gray-400 hover:text-gray-600"
              >
                <X className="w-6 h-6" />
              </button>
            </div>
            <div className="p-6">
              <AlertManager filter={currentFilter} />
            </div>
          </div>
        </div>
      )}

      {showTravelersModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg max-w-md w-full">
            <div className="flex items-center justify-between p-6 border-b border-gray-200">
              <h3 className="text-lg font-semibold">Travelers & Cabin Class</h3>
              <button
                onClick={() => setShowTravelersModal(false)}
                className="text-gray-400 hover:text-gray-600"
              >
                <X className="w-6 h-6" />
              </button>
            </div>
            <div className="p-6 space-y-6">
              {/* Adults */}
              <div className="flex items-center justify-between">
                <div>
                  <h4 className="font-medium text-gray-900">Adults</h4>
                  <p className="text-sm text-gray-500">12+ years</p>
                </div>
                <div className="flex items-center space-x-3">
                  <button
                    onClick={() => {
                      if (currentFilter.passengers.adults > 1) {
                        updateFilter({
                          passengers: { ...currentFilter.passengers, adults: currentFilter.passengers.adults - 1 }
                        });
                      }
                    }}
                    className="w-8 h-8 rounded-full border border-gray-300 flex items-center justify-center hover:bg-gray-50"
                    disabled={currentFilter.passengers.adults <= 1}
                  >
                    <Minus className="w-4 h-4" />
                  </button>
                  <span className="w-8 text-center">{currentFilter.passengers.adults}</span>
                  <button
                    onClick={() => {
                      updateFilter({
                        passengers: { ...currentFilter.passengers, adults: currentFilter.passengers.adults + 1 }
                      });
                    }}
                    className="w-8 h-8 rounded-full border border-gray-300 flex items-center justify-center hover:bg-gray-50"
                  >
                    <Plus className="w-4 h-4" />
                  </button>
                </div>
              </div>

              {/* Children */}
              <div className="flex items-center justify-between">
                <div>
                  <h4 className="font-medium text-gray-900">Children</h4>
                  <p className="text-sm text-gray-500">2-11 years</p>
                </div>
                <div className="flex items-center space-x-3">
                  <button
                    onClick={() => {
                      if (currentFilter.passengers.children > 0) {
                        updateFilter({
                          passengers: { ...currentFilter.passengers, children: currentFilter.passengers.children - 1 }
                        });
                      }
                    }}
                    className="w-8 h-8 rounded-full border border-gray-300 flex items-center justify-center hover:bg-gray-50"
                    disabled={currentFilter.passengers.children <= 0}
                  >
                    <Minus className="w-4 h-4" />
                  </button>
                  <span className="w-8 text-center">{currentFilter.passengers.children}</span>
                  <button
                    onClick={() => {
                      updateFilter({
                        passengers: { ...currentFilter.passengers, children: currentFilter.passengers.children + 1 }
                      });
                    }}
                    className="w-8 h-8 rounded-full border border-gray-300 flex items-center justify-center hover:bg-gray-50"
                  >
                    <Plus className="w-4 h-4" />
                  </button>
                </div>
              </div>

              {/* Infants */}
              <div className="flex items-center justify-between">
                <div>
                  <h4 className="font-medium text-gray-900">Infants</h4>
                  <p className="text-sm text-gray-500">Under 2 years</p>
                </div>
                <div className="flex items-center space-x-3">
                  <button
                    onClick={() => {
                      if (currentFilter.passengers.infants > 0) {
                        updateFilter({
                          passengers: { ...currentFilter.passengers, infants: currentFilter.passengers.infants - 1 }
                        });
                      }
                    }}
                    className="w-8 h-8 rounded-full border border-gray-300 flex items-center justify-center hover:bg-gray-50"
                    disabled={currentFilter.passengers.infants <= 0}
                  >
                    <Minus className="w-4 h-4" />
                  </button>
                  <span className="w-8 text-center">{currentFilter.passengers.infants}</span>
                  <button
                    onClick={() => {
                      updateFilter({
                        passengers: { ...currentFilter.passengers, infants: currentFilter.passengers.infants + 1 }
                      });
                    }}
                    className="w-8 h-8 rounded-full border border-gray-300 flex items-center justify-center hover:bg-gray-50"
                  >
                    <Plus className="w-4 h-4" />
                  </button>
                </div>
              </div>

              {/* Cabin Class */}
              <div>
                <h4 className="font-medium text-gray-900 mb-3">Cabin Class</h4>
                <div className="space-y-2">
                  {['economy', 'premium-economy', 'business', 'first'].map((cabin) => (
                    <label key={cabin} className="flex items-center">
                      <input
                        type="radio"
                        name="cabinClass"
                        value={cabin}
                        checked={currentFilter.cabinClass === cabin}
                        onChange={(e) => updateFilter({ cabinClass: e.target.value as any })}
                        className="mr-3"
                      />
                      <span className="capitalize">{cabin.replace('-', ' ')}</span>
                    </label>
                  ))}
                </div>
              </div>

              <button
                onClick={() => setShowTravelersModal(false)}
                className="w-full bg-blue-600 text-white py-3 rounded-lg font-medium hover:bg-blue-700 transition-colors"
              >
                Done
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default FlightSearchInterface;
