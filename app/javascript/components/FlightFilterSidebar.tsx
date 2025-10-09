import React, { useState, useEffect } from 'react';
import { 
  Plane, 
  MapPin, 
  Calendar, 
  Clock, 
  DollarSign, 
  Users, 
  ChevronDown, 
  ChevronUp,
  Zap,
  TrendingUp,
  TrendingDown,
  Target,
  Bell,
  Settings,
  Check,
  X,
  AlertTriangle,
  Info,
  Star,
  Shield,
  Timer,
  BarChart3,
  Smartphone,
  Mail,
  MessageSquare,
  Plus,
  Minus
} from 'lucide-react';
import { FlightFilter, Airport } from '../types/flight-filter';

interface FlightFilterSidebarProps {
  filter: FlightFilter;
  updateFilter: (updates: Partial<FlightFilter>) => void;
  onSaveFilter?: () => void;
  onTestAlert?: () => void;
  onClose?: () => void;
  className?: string;
}

const FlightFilterSidebar: React.FC<FlightFilterSidebarProps> = ({
  filter,
  updateFilter,
  onSaveFilter,
  onTestAlert,
  onClose,
  className = ""
}) => {
  const [expandedSections, setExpandedSections] = useState({
    route: true,
    priceBreak: true,
    stops: true,
    times: true,
    airlines: false,
    priceRange: false,
    autoBuy: false,
    alerts: false
  });

  const [showAirlineDropdown, setShowAirlineDropdown] = useState(false);
  const [airlineSearch, setAirlineSearch] = useState('');

  const airlines = [
    { code: 'DL', name: 'Delta Air Lines', logo: '🔺' },
    { code: 'AA', name: 'American Airlines', logo: '✈️' },
    { code: 'UA', name: 'United Airlines', logo: '🌍' },
    { code: 'WN', name: 'Southwest Airlines', logo: '💙' },
    { code: 'B6', name: 'JetBlue Airways', logo: '💙' },
    { code: 'AS', name: 'Alaska Airlines', logo: '🏔️' },
    { code: 'NK', name: 'Spirit Airlines', logo: '💛' },
    { code: 'F9', name: 'Frontier Airlines', logo: '🦅' },
    { code: 'BA', name: 'British Airways', logo: '🇬🇧' },
    { code: 'LH', name: 'Lufthansa', logo: '🇩🇪' },
    { code: 'AF', name: 'Air France', logo: '🇫🇷' },
    { code: 'KL', name: 'KLM', logo: '🇳🇱' },
    { code: 'EK', name: 'Emirates', logo: '🇦🇪' },
    { code: 'QR', name: 'Qatar Airways', logo: '🇶🇦' }
  ];

  const timeSlots = [
    { value: 'morning', label: 'Morning', time: '6AM - 12PM', icon: '🌅' },
    { value: 'afternoon', label: 'Afternoon', time: '12PM - 6PM', icon: '☀️' },
    { value: 'evening', label: 'Evening', time: '6PM - 12AM', icon: '🌆' },
    { value: 'red-eye', label: 'Red-eye', time: '12AM - 6AM', icon: '🌙' }
  ];

  const stopOptions = [
    { value: 'nonstop', label: 'Nonstop', description: 'Direct flights only', count: 45 },
    { value: '1-stop', label: '1 Stop', description: 'One connection max', count: 23 },
    { value: '2+', label: '2+ Stops', description: 'Multiple connections OK', count: 8 }
  ];

  const toggleSection = (section: keyof typeof expandedSections) => {
    setExpandedSections(prev => ({
      ...prev,
      [section]: !prev[section]
    }));
  };

  const updatePassengers = (type: 'adults' | 'children' | 'infants', value: number) => {
    const newPassengers = { ...filter.passengers, [type]: Math.max(0, value) };
    updateFilter({ passengers: newPassengers });
  };

  const toggleAirline = (airline: string) => {
    const current = filter.airlinePreferences || [];
    const updated = current.includes(airline) 
      ? current.filter(a => a !== airline)
      : [...current, airline];
    updateFilter({ airlinePreferences: updated });
  };

  const toggleTimeSlot = (type: 'departure' | 'arrival', slot: string) => {
    const current = filter.preferredTimes?.[type] || [];
    const updated = current.includes(slot)
      ? current.filter(t => t !== slot)
      : [...current, slot];
    updateFilter({ 
      preferredTimes: { 
        ...filter.preferredTimes, 
        [type]: updated 
      } 
    });
  };

  const filteredAirlines = airlines.filter(airline =>
    airline.name.toLowerCase().includes(airlineSearch.toLowerCase()) ||
    airline.code.toLowerCase().includes(airlineSearch.toLowerCase())
  );

  const formatPrice = (price: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: filter.currency || 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(price);
  };

  return (
    <div className={`bg-white border-r border-gray-200 w-80 flex flex-col h-full ${className}`}>
      {/* Header */}
      <div className="p-6 border-b border-gray-200 bg-gradient-to-r from-blue-600 to-blue-700 text-white">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-lg font-semibold">Flight Filters</h2>
            <p className="text-blue-100 text-sm">Customize your search</p>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={onTestAlert}
              className="p-2 rounded-lg bg-blue-500 hover:bg-blue-400 transition-colors"
              title="Test Alert"
            >
              <Bell className="w-4 h-4" />
            </button>
            <button
              onClick={onSaveFilter}
              className="p-2 rounded-lg bg-blue-500 hover:bg-blue-400 transition-colors"
              title="Save Filter"
            >
              <Settings className="w-4 h-4" />
            </button>
            {onClose && (
              <button
                onClick={onClose}
                className="p-2 rounded-lg bg-blue-500 hover:bg-blue-400 transition-colors md:hidden"
                title="Close Filters"
              >
                <X className="w-4 h-4" />
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Filter Content */}
      <div className="flex-1 overflow-y-auto">
        
        {/* Route & Dates Section */}
        <div className="border-b border-gray-200">
          <button
            onClick={() => toggleSection('route')}
            className="w-full px-6 py-4 flex items-center justify-between hover:bg-gray-50 transition-colors"
          >
            <div className="flex items-center gap-3">
              <MapPin className="w-5 h-5 text-blue-600" />
              <span className="font-medium">Route & Dates</span>
            </div>
            {expandedSections.route ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
          </button>
          
          {expandedSections.route && (
            <div className="px-6 pb-4 space-y-4">
              {/* Trip Type */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Trip Type</label>
                <div className="flex rounded-lg bg-gray-100 p-1">
                  {['one-way', 'round-trip', 'multi-city'].map((type) => (
                    <button
                      key={type}
                      onClick={() => updateFilter({ tripType: type as any })}
                      className={`flex-1 px-3 py-2 text-sm rounded-md transition-colors ${
                        filter.tripType === type
                          ? 'bg-white text-blue-600 shadow-sm'
                          : 'text-gray-600 hover:text-gray-800'
                      }`}
                    >
                      {type.split('-').map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(' ')}
                    </button>
                  ))}
                </div>
              </div>

              {/* Origin & Destination */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">From</label>
                  <div className="relative">
                    <input
                      type="text"
                      placeholder="City or airport"
                      value={filter.origin?.name || ''}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      readOnly
                    />
                    <MapPin className="absolute right-3 top-2.5 w-4 h-4 text-gray-400" />
                  </div>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">To</label>
                  <div className="relative">
                    <input
                      type="text"
                      placeholder="City or airport"
                      value={filter.destination?.name || ''}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      readOnly
                    />
                    <MapPin className="absolute right-3 top-2.5 w-4 h-4 text-gray-400" />
                  </div>
                </div>
              </div>

              {/* Dates */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Departure</label>
                  <div className="relative">
                    <input
                      type="date"
                      value={filter.departureDate ? filter.departureDate.toISOString().split('T')[0] : ''}
                      onChange={(e) => updateFilter({ departureDate: e.target.value ? new Date(e.target.value) : null })}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    />
                    <Calendar className="absolute right-3 top-2.5 w-4 h-4 text-gray-400" />
                  </div>
                </div>
                {filter.tripType === 'round-trip' && (
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Return</label>
                    <div className="relative">
                      <input
                        type="date"
                        value={filter.returnDate ? filter.returnDate.toISOString().split('T')[0] : ''}
                        onChange={(e) => updateFilter({ returnDate: e.target.value ? new Date(e.target.value) : null })}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      />
                      <Calendar className="absolute right-3 top-2.5 w-4 h-4 text-gray-400" />
                    </div>
                  </div>
                )}
              </div>

              {/* Flexible Dates */}
              <div className="flex items-center justify-between">
                <label className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={filter.flexibleDates || false}
                    onChange={(e) => updateFilter({ flexibleDates: e.target.checked })}
                    className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                  />
                  <span className="text-sm font-medium text-gray-700">Flexible dates</span>
                </label>
                {filter.flexibleDates && (
                  <span className="text-xs text-gray-500">±{filter.dateFlexibility || 3} days</span>
                )}
              </div>

              {/* Passengers */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Passengers</label>
                <div className="space-y-2">
                  {[
                    { type: 'adults', label: 'Adults (12+)', icon: '👤' },
                    { type: 'children', label: 'Children (2-11)', icon: '🧒' },
                    { type: 'infants', label: 'Infants (0-1)', icon: '👶' }
                  ].map(({ type, label, icon }) => (
                    <div key={type} className="flex items-center justify-between">
                      <span className="text-sm text-gray-600">{icon} {label}</span>
                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => updatePassengers(type as any, (filter.passengers[type as keyof typeof filter.passengers] || 0) - 1)}
                          className="w-6 h-6 rounded-full bg-gray-200 hover:bg-gray-300 flex items-center justify-center text-gray-600"
                        >
                          <Minus className="w-3 h-3" />
                        </button>
                        <span className="w-8 text-center text-sm font-medium">
                          {filter.passengers[type as keyof typeof filter.passengers] || 0}
                        </span>
                        <button
                          onClick={() => updatePassengers(type as any, (filter.passengers[type as keyof typeof filter.passengers] || 0) + 1)}
                          className="w-6 h-6 rounded-full bg-gray-200 hover:bg-gray-300 flex items-center justify-center text-gray-600"
                        >
                          <Plus className="w-3 h-3" />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}
        </div>

        {/* PriceBreak Features Section */}
        <div className="border-b border-gray-200">
          <button
            onClick={() => toggleSection('priceBreak')}
            className="w-full px-6 py-4 flex items-center justify-between hover:bg-gray-50 transition-colors"
          >
            <div className="flex items-center gap-3">
              <Zap className="w-5 h-5 text-amber-500" />
              <span className="font-medium">PriceBreak Features</span>
              <span className="bg-amber-100 text-amber-800 text-xs px-2 py-1 rounded-full">Pro</span>
            </div>
            {expandedSections.priceBreak ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
          </button>
          
          {expandedSections.priceBreak && (
            <div className="px-6 pb-4 space-y-4">
              {/* Target Price */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Target Price {formatPrice(filter.targetPrice || 0)}
                </label>
                <input
                  type="range"
                  min="0"
                  max="2000"
                  step="50"
                  value={filter.targetPrice || 0}
                  onChange={(e) => updateFilter({ targetPrice: parseInt(e.target.value) })}
                  className="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer slider"
                />
                <div className="flex justify-between text-xs text-gray-500 mt-1">
                  <span>$0</span>
                  <span>$2000</span>
                </div>
              </div>

              {/* Price Drop Alert */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Price Drop Alert: {filter.priceDropPercentage || 20}%
                </label>
                <input
                  type="range"
                  min="5"
                  max="50"
                  step="5"
                  value={filter.priceDropPercentage || 20}
                  onChange={(e) => updateFilter({ priceDropPercentage: parseInt(e.target.value) })}
                  className="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer slider"
                />
                <div className="flex justify-between text-xs text-gray-500 mt-1">
                  <span>5%</span>
                  <span>50%</span>
                </div>
              </div>

              {/* Price Confidence */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Price Confidence</label>
                <div className="space-y-2">
                  {[
                    { value: 'low', label: 'Low', description: 'High volatility expected', color: 'text-red-600' },
                    { value: 'medium', label: 'Medium', description: 'Moderate price changes', color: 'text-amber-600' },
                    { value: 'high', label: 'High', description: 'Stable pricing expected', color: 'text-green-600' }
                  ].map(({ value, label, description, color }) => (
                    <label key={value} className="flex items-start gap-3 cursor-pointer">
                      <input
                        type="radio"
                        name="priceConfidence"
                        value={value}
                        checked={filter.priceBreakConfidence === value}
                        onChange={(e) => updateFilter({ priceBreakConfidence: e.target.value as any })}
                        className="mt-0.5"
                      />
                      <div>
                        <div className={`text-sm font-medium ${color}`}>{label}</div>
                        <div className="text-xs text-gray-500">{description}</div>
                      </div>
                    </label>
                  ))}
                </div>
              </div>

              {/* Instant Price Break Alerts */}
              <div className="bg-blue-50 p-3 rounded-lg">
                <div className="flex items-center gap-2 mb-2">
                  <Bell className="w-4 h-4 text-blue-600" />
                  <span className="text-sm font-medium text-blue-900">Instant Price Break Alerts</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-blue-700">Enable instant alerts</span>
                  <input
                    type="checkbox"
                    checked={filter.instantPriceBreakAlerts?.enabled || false}
                    onChange={(e) => updateFilter({ 
                      instantPriceBreakAlerts: { 
                        ...filter.instantPriceBreakAlerts, 
                        enabled: e.target.checked 
                      } 
                    })}
                    className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                  />
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Stops Section */}
        <div className="border-b border-gray-200">
          <button
            onClick={() => toggleSection('stops')}
            className="w-full px-6 py-4 flex items-center justify-between hover:bg-gray-50 transition-colors"
          >
            <div className="flex items-center gap-3">
              <Plane className="w-5 h-5 text-blue-600" />
              <span className="font-medium">Stops</span>
            </div>
            {expandedSections.stops ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
          </button>
          
          {expandedSections.stops && (
            <div className="px-6 pb-4 space-y-3">
              {stopOptions.map((option) => (
                <label key={option.value} className="flex items-center justify-between cursor-pointer">
                  <div className="flex items-center gap-3">
                    <input
                      type="radio"
                      name="stops"
                      value={option.value}
                      checked={filter.maxStops === option.value}
                      onChange={(e) => updateFilter({ maxStops: e.target.value as any })}
                      className="text-blue-600 focus:ring-blue-500"
                    />
                    <div>
                      <div className="text-sm font-medium text-gray-900">{option.label}</div>
                      <div className="text-xs text-gray-500">{option.description}</div>
                    </div>
                  </div>
                  <span className="text-sm text-gray-500">{option.count}</span>
                </label>
              ))}
            </div>
          )}
        </div>

        {/* Times Section */}
        <div className="border-b border-gray-200">
          <button
            onClick={() => toggleSection('times')}
            className="w-full px-6 py-4 flex items-center justify-between hover:bg-gray-50 transition-colors"
          >
            <div className="flex items-center gap-3">
              <Clock className="w-5 h-5 text-blue-600" />
              <span className="font-medium">Departure Times</span>
            </div>
            {expandedSections.times ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
          </button>
          
          {expandedSections.times && (
            <div className="px-6 pb-4 space-y-4">
              {timeSlots.map((slot) => (
                <label key={slot.value} className="flex items-center justify-between cursor-pointer">
                  <div className="flex items-center gap-3">
                    <input
                      type="checkbox"
                      checked={filter.preferredTimes?.departure?.includes(slot.value) || false}
                      onChange={(e) => toggleTimeSlot('departure', slot.value)}
                      className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                    />
                    <div className="flex items-center gap-2">
                      <span className="text-lg">{slot.icon}</span>
                      <div>
                        <div className="text-sm font-medium text-gray-900">{slot.label}</div>
                        <div className="text-xs text-gray-500">{slot.time}</div>
                      </div>
                    </div>
                  </div>
                  <span className="text-sm text-gray-500">24</span>
                </label>
              ))}
            </div>
          )}
        </div>

        {/* Airlines Section */}
        <div className="border-b border-gray-200">
          <button
            onClick={() => toggleSection('airlines')}
            className="w-full px-6 py-4 flex items-center justify-between hover:bg-gray-50 transition-colors"
          >
            <div className="flex items-center gap-3">
              <Plane className="w-5 h-5 text-blue-600" />
              <span className="font-medium">Airlines</span>
              {filter.airlinePreferences?.length > 0 && (
                <span className="bg-blue-100 text-blue-800 text-xs px-2 py-1 rounded-full">
                  {filter.airlinePreferences.length}
                </span>
              )}
            </div>
            {expandedSections.airlines ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
          </button>
          
          {expandedSections.airlines && (
            <div className="px-6 pb-4">
              <div className="relative mb-3">
                <input
                  type="text"
                  placeholder="Search airlines..."
                  value={airlineSearch}
                  onChange={(e) => setAirlineSearch(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <div className="max-h-48 overflow-y-auto space-y-2">
                {filteredAirlines.map((airline) => (
                  <label key={airline.code} className="flex items-center justify-between cursor-pointer">
                    <div className="flex items-center gap-3">
                      <input
                        type="checkbox"
                        checked={filter.airlinePreferences?.includes(airline.name) || false}
                        onChange={() => toggleAirline(airline.name)}
                        className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                      />
                      <div className="flex items-center gap-2">
                        <span className="text-lg">{airline.logo}</span>
                        <div>
                          <div className="text-sm font-medium text-gray-900">{airline.name}</div>
                          <div className="text-xs text-gray-500">{airline.code}</div>
                        </div>
                      </div>
                    </div>
                    <span className="text-sm text-gray-500">$456</span>
                  </label>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Price Range Section */}
        <div className="border-b border-gray-200">
          <button
            onClick={() => toggleSection('priceRange')}
            className="w-full px-6 py-4 flex items-center justify-between hover:bg-gray-50 transition-colors"
          >
            <div className="flex items-center gap-3">
              <DollarSign className="w-5 h-5 text-green-600" />
              <span className="font-medium">Price Range</span>
            </div>
            {expandedSections.priceRange ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
          </button>
          
          {expandedSections.priceRange && (
            <div className="px-6 pb-4 space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Budget: {formatPrice(filter.budgetRange?.min || 0)} - {formatPrice(filter.budgetRange?.max || 1000)}
                </label>
                <div className="space-y-2">
                  <input
                    type="range"
                    min="0"
                    max="2000"
                    step="50"
                    value={filter.budgetRange?.min || 0}
                    onChange={(e) => updateFilter({ 
                      budgetRange: { 
                        ...filter.budgetRange, 
                        min: parseInt(e.target.value) 
                      } 
                    })}
                    className="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer slider"
                  />
                  <input
                    type="range"
                    min="0"
                    max="2000"
                    step="50"
                    value={filter.budgetRange?.max || 1000}
                    onChange={(e) => updateFilter({ 
                      budgetRange: { 
                        ...filter.budgetRange, 
                        max: parseInt(e.target.value) 
                      } 
                    })}
                    className="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer slider"
                  />
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Auto-Buy Section */}
        <div className="border-b border-gray-200">
          <button
            onClick={() => toggleSection('autoBuy')}
            className="w-full px-6 py-4 flex items-center justify-between hover:bg-gray-50 transition-colors"
          >
            <div className="flex items-center gap-3">
              <Shield className="w-5 h-5 text-purple-600" />
              <span className="font-medium">Auto-Buy</span>
              <span className="bg-purple-100 text-purple-800 text-xs px-2 py-1 rounded-full">Premium</span>
            </div>
            {expandedSections.autoBuy ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
          </button>
          
          {expandedSections.autoBuy && (
            <div className="px-6 pb-4 space-y-4">
              <div className="bg-purple-50 p-3 rounded-lg">
                <div className="flex items-center gap-2 mb-2">
                  <AlertTriangle className="w-4 h-4 text-purple-600" />
                  <span className="text-sm font-medium text-purple-900">Auto-Buy Settings</span>
                </div>
                <p className="text-xs text-purple-700 mb-3">
                  Automatically purchase flights when your criteria are met
                </p>
                
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-purple-700">Enable Auto-Buy</span>
                    <input
                      type="checkbox"
                      className="rounded border-gray-300 text-purple-600 focus:ring-purple-500"
                    />
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-purple-700 mb-1">
                      Max Auto-Buy Price: {formatPrice(800)}
                    </label>
                    <input
                      type="range"
                      min="0"
                      max="1500"
                      step="50"
                      value="800"
                      className="w-full h-2 bg-purple-200 rounded-lg appearance-none cursor-pointer slider"
                    />
                  </div>
                  
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-purple-700">Confirm before purchase</span>
                    <input
                      type="checkbox"
                      defaultChecked
                      className="rounded border-gray-300 text-purple-600 focus:ring-purple-500"
                    />
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Alert Preferences Section */}
        <div>
          <button
            onClick={() => toggleSection('alerts')}
            className="w-full px-6 py-4 flex items-center justify-between hover:bg-gray-50 transition-colors"
          >
            <div className="flex items-center gap-3">
              <Bell className="w-5 h-5 text-blue-600" />
              <span className="font-medium">Alert Preferences</span>
            </div>
            {expandedSections.alerts ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
          </button>
          
          {expandedSections.alerts && (
            <div className="px-6 pb-4 space-y-4">
              {/* Monitor Frequency */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Monitor Frequency</label>
                <select
                  value={filter.monitorFrequency || 'daily'}
                  onChange={(e) => updateFilter({ monitorFrequency: e.target.value as any })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="real-time">Real-time (Premium)</option>
                  <option value="hourly">Hourly</option>
                  <option value="daily">Daily</option>
                  <option value="weekly">Weekly</option>
                </select>
              </div>

              {/* Alert Urgency */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Alert Urgency</label>
                <div className="space-y-2">
                  {[
                    { value: 'patient', label: 'Patient', description: 'Only significant drops', color: 'text-green-600' },
                    { value: 'moderate', label: 'Moderate', description: 'Regular price updates', color: 'text-amber-600' },
                    { value: 'urgent', label: 'Urgent', description: 'All price changes', color: 'text-red-600' }
                  ].map(({ value, label, description, color }) => (
                    <label key={value} className="flex items-start gap-3 cursor-pointer">
                      <input
                        type="radio"
                        name="alertUrgency"
                        value={value}
                        checked={filter.alertUrgency === value}
                        onChange={(e) => updateFilter({ alertUrgency: e.target.value as any })}
                        className="mt-0.5"
                      />
                      <div>
                        <div className={`text-sm font-medium ${color}`}>{label}</div>
                        <div className="text-xs text-gray-500">{description}</div>
                      </div>
                    </label>
                  ))}
                </div>
              </div>

              {/* Notification Methods */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Notification Methods</label>
                <div className="space-y-2">
                  {[
                    { key: 'email', label: 'Email', icon: Mail },
                    { key: 'sms', label: 'SMS', icon: MessageSquare },
                    { key: 'push', label: 'Push Notification', icon: Smartphone },
                    { key: 'browser', label: 'Browser Notification', icon: Bell }
                  ].map(({ key, label, icon: Icon }) => (
                    <div key={key} className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <Icon className="w-4 h-4 text-gray-500" />
                        <span className="text-sm text-gray-700">{label}</span>
                      </div>
                      <input
                        type="checkbox"
                        checked={filter.notificationMethods?.[key as keyof typeof filter.notificationMethods] || false}
                        onChange={(e) => updateFilter({ 
                          notificationMethods: { 
                            ...filter.notificationMethods, 
                            [key]: e.target.checked 
                          } 
                        })}
                        className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                      />
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Footer Actions */}
      <div className="p-6 border-t border-gray-200 bg-gray-50">
        <div className="space-y-3">
          <button
            onClick={onSaveFilter}
            className="w-full bg-blue-600 text-white py-3 px-4 rounded-lg font-medium hover:bg-blue-700 transition-colors flex items-center justify-center gap-2"
          >
            <Save className="w-4 h-4" />
            Save Filter
          </button>
          <button
            onClick={onTestAlert}
            className="w-full bg-gray-200 text-gray-700 py-2 px-4 rounded-lg font-medium hover:bg-gray-300 transition-colors flex items-center justify-center gap-2"
          >
            <Bell className="w-4 h-4" />
            Test Alert
          </button>
        </div>
      </div>
    </div>
  );
};

export default FlightFilterSidebar;
