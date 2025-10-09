import React, { useState, useEffect, useRef, useCallback, useMemo } from 'react';
import { MapPin, Loader2, X, Plane, Globe, Search } from 'lucide-react';
import { Airport } from '../types/flight-filter';
import { AirportService } from '../lib/firebase';
import { getPopularAirports } from '../lib/airportDatabase';

interface AirportAutocompleteProps {
  value: string;
  onChange: (value: string) => void;
  onSelect: (airport: Airport | null) => void;
  placeholder?: string;
  label?: string;
  error?: string;
  disabled?: boolean;
  className?: string;
  selectedAirport?: Airport | null;
  showPopularAirports?: boolean;
  size?: 'sm' | 'md' | 'lg';
  variant?: 'default' | 'minimal' | 'outlined';
}

const AirportAutocomplete: React.FC<AirportAutocompleteProps> = ({
  value,
  onChange,
  onSelect,
  placeholder = "Search airports...",
  label,
  error,
  disabled = false,
  className = "",
  selectedAirport,
  showPopularAirports = true,
  size = 'md',
  variant = 'default'
}) => {
  const [isOpen, setIsOpen] = useState(false);
  const [airports, setAirports] = useState<Airport[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [highlightedIndex, setHighlightedIndex] = useState(-1);
  const [hasSearched, setHasSearched] = useState(false);
  
  const inputRef = useRef<HTMLInputElement>(null);
  const dropdownRef = useRef<HTMLDivElement>(null);
  const debouncedSearch = useRef<ReturnType<typeof AirportService.debounce>>();

  // Get popular airports for initial display
  const popularAirports = useMemo(() => getPopularAirports(), []);

  // Initialize debounced search function
  useEffect(() => {
    debouncedSearch.current = AirportService.debounce(async (searchTerm: string) => {
      if (!searchTerm || searchTerm.trim().length < 2) {
        setAirports([]);
        setIsLoading(false);
        setHasSearched(false);
        return;
      }

      setIsLoading(true);
      setHasSearched(true);
      try {
        const results = await AirportService.searchAirports(searchTerm);
        setAirports(results);
      } catch (error) {
        console.error('Error searching airports:', error);
        setAirports([]);
      } finally {
        setIsLoading(false);
      }
    }, 300);
  }, []);

  // Handle input change
  const handleInputChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const newValue = e.target.value;
    onChange(newValue);
    
    // Clear selection if user is typing
    if (selectedAirport && newValue !== `${selectedAirport.iata_code} - ${selectedAirport.city}`) {
      onSelect(null);
    }
    
    // Trigger search
    if (debouncedSearch.current) {
      setIsOpen(true);
      debouncedSearch.current(newValue);
    }
  }, [onChange, onSelect, selectedAirport]);

  // Get size classes
  const getSizeClasses = useCallback(() => {
    switch (size) {
      case 'sm':
        return 'px-3 py-2 text-sm';
      case 'lg':
        return 'px-5 py-4 text-lg';
      default:
        return 'px-4 py-3 text-base';
    }
  }, [size]);

  // Get variant classes
  const getVariantClasses = useCallback(() => {
    switch (variant) {
      case 'minimal':
        return 'border-0 border-b-2 border-gray-300 bg-transparent focus:border-blue-500 rounded-none';
      case 'outlined':
        return 'border-2 border-gray-300 bg-white focus:border-blue-500 rounded-lg';
      default:
        return 'border border-gray-300 bg-white focus:border-blue-500 rounded-lg';
    }
  }, [variant]);

  // Handle airport selection
  const handleSelectAirport = useCallback((airport: Airport) => {
    const displayValue = `${airport.iata_code} - ${airport.city}`;
    onChange(displayValue);
    onSelect(airport);
    setIsOpen(false);
    setHighlightedIndex(-1);
    inputRef.current?.blur();
  }, [onChange, onSelect]);

  // Handle input focus
  const handleFocus = useCallback(() => {
    if (!disabled) {
      setIsOpen(true);
      if (value && debouncedSearch.current) {
        debouncedSearch.current(value);
      }
    }
  }, [disabled, value]);

  // Handle input blur
  const handleBlur = useCallback((e: React.FocusEvent) => {
    // Don't close if clicking on dropdown
    if (dropdownRef.current?.contains(e.relatedTarget as Node)) {
      return;
    }
    
    // Close dropdown after a short delay to allow for click events
    setTimeout(() => {
      setIsOpen(false);
      setHighlightedIndex(-1);
    }, 150);
  }, []);

  // Handle keyboard navigation
  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (!isOpen || airports.length === 0) {
      if (e.key === 'ArrowDown') {
        e.preventDefault();
        setIsOpen(true);
        if (debouncedSearch.current) {
          debouncedSearch.current(value);
        }
      }
      return;
    }

    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault();
        setHighlightedIndex(prev => 
          prev < airports.length - 1 ? prev + 1 : 0
        );
        break;
      case 'ArrowUp':
        e.preventDefault();
        setHighlightedIndex(prev => 
          prev > 0 ? prev - 1 : airports.length - 1
        );
        break;
      case 'Enter':
        e.preventDefault();
        if (highlightedIndex >= 0 && highlightedIndex < airports.length) {
          handleSelectAirport(airports[highlightedIndex]);
        }
        break;
      case 'Escape':
        setIsOpen(false);
        setHighlightedIndex(-1);
        inputRef.current?.blur();
        break;
    }
  }, [isOpen, airports, highlightedIndex, value, handleSelectAirport]);

  // Clear selection
  const handleClear = useCallback(() => {
    onChange('');
    onSelect(null);
    setIsOpen(false);
    setHighlightedIndex(-1);
    inputRef.current?.focus();
  }, [onChange, onSelect]);

  // Click outside handler
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (
        inputRef.current && 
        !inputRef.current.contains(event.target as Node) &&
        dropdownRef.current &&
        !dropdownRef.current.contains(event.target as Node)
      ) {
        setIsOpen(false);
        setHighlightedIndex(-1);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Determine what to show in dropdown
  const dropdownContent = useMemo(() => {
    if (isLoading) {
      return (
        <div className="px-4 py-6 text-center">
          <Loader2 className="h-6 w-6 text-blue-500 animate-spin mx-auto mb-2" />
          <p className="text-sm text-gray-600">Searching airports...</p>
        </div>
      );
    }

    if (hasSearched && airports.length === 0) {
      return (
        <div className="px-4 py-6 text-center">
          <Search className="h-6 w-6 text-gray-400 mx-auto mb-2" />
          <p className="text-sm text-gray-600">No airports found</p>
          <p className="text-xs text-gray-500 mt-1">Try searching by city, country, or airport code</p>
        </div>
      );
    }

    if (airports.length > 0) {
      return airports.map((airport, index) => (
        <button
          key={`${airport.iata_code}-${index}`}
          type="button"
          onClick={() => handleSelectAirport(airport)}
          className={`
            w-full text-left px-4 py-3 hover:bg-gray-50 border-b border-gray-100 last:border-b-0 transition-colors
            ${index === highlightedIndex ? 'bg-blue-50 border-blue-200' : ''}
          `}
        >
          <div className="flex items-center justify-between">
            <div className="flex-1 min-w-0">
              <div className="flex items-center space-x-2">
                <span className="font-semibold text-gray-900 text-sm">
                  {airport.iata_code}
                </span>
                <span className="text-xs text-gray-500">
                  {airport.icao_code}
                </span>
              </div>
              <div className="text-sm text-gray-700 font-medium truncate">
                {airport.city}, {airport.country}
              </div>
              <div className="text-xs text-gray-500 truncate">
                {airport.name}
              </div>
            </div>
            <div className="flex-shrink-0 ml-3">
              <MapPin className="h-4 w-4 text-gray-400" />
            </div>
          </div>
        </button>
      ));
    }

    // Show popular airports when no search has been performed
    if (showPopularAirports && !hasSearched) {
      return (
        <div>
          <div className="px-4 py-2 bg-gray-50 border-b border-gray-200">
            <div className="flex items-center space-x-2">
              <Globe className="h-4 w-4 text-gray-500" />
              <span className="text-xs font-medium text-gray-700">Popular Destinations</span>
            </div>
          </div>
          {popularAirports.slice(0, 8).map((airport, index) => (
            <button
              key={`popular-${airport.iata_code}-${index}`}
              type="button"
              onClick={() => handleSelectAirport(airport)}
              className={`
                w-full text-left px-4 py-3 hover:bg-gray-50 border-b border-gray-100 last:border-b-0 transition-colors
                ${index === highlightedIndex ? 'bg-blue-50 border-blue-200' : ''}
              `}
            >
              <div className="flex items-center justify-between">
                <div className="flex-1 min-w-0">
                  <div className="flex items-center space-x-2">
                    <span className="font-semibold text-gray-900 text-sm">
                      {airport.iata_code}
                    </span>
                    <span className="text-xs text-gray-500">
                      {airport.icao_code}
                    </span>
                  </div>
                  <div className="text-sm text-gray-700 font-medium truncate">
                    {airport.city}, {airport.country}
                  </div>
                  <div className="text-xs text-gray-500 truncate">
                    {airport.name}
                  </div>
                </div>
                <div className="flex-shrink-0 ml-3">
                  <Plane className="h-4 w-4 text-gray-400" />
                </div>
              </div>
            </button>
          ))}
        </div>
      );
    }

    return null;
  }, [isLoading, hasSearched, airports, popularAirports, showPopularAirports, highlightedIndex, handleSelectAirport]);

  return (
    <div className={`relative ${className}`}>
      {label && (
        <label className="block text-sm font-medium text-gray-700 mb-2">
          {label}
        </label>
      )}
      
      <div className="relative">
        <input
          ref={inputRef}
          type="text"
          value={value}
          onChange={handleInputChange}
          onFocus={handleFocus}
          onBlur={handleBlur}
          onKeyDown={handleKeyDown}
          placeholder={placeholder}
          disabled={disabled}
          className={`
            w-full ${getSizeClasses()} pr-12 ${getVariantClasses()}
            focus:ring-2 focus:ring-blue-500 focus:outline-none transition-colors
            ${error ? 'border-red-300 focus:ring-red-500 focus:border-red-500' : ''}
            ${disabled ? 'bg-gray-100 cursor-not-allowed text-gray-500' : 'text-gray-900'}
          `}
          autoComplete="off"
          aria-expanded={isOpen}
          aria-haspopup="listbox"
          role="combobox"
          aria-autocomplete="list"
        />
        
        <div className="absolute right-3 top-1/2 transform -translate-y-1/2 flex items-center space-x-1">
          {isLoading && (
            <Loader2 className="h-4 w-4 text-gray-400 animate-spin" />
          )}
          
          {!isLoading && !selectedAirport && (
            <MapPin className="h-4 w-4 text-gray-400" />
          )}
          
          {selectedAirport && (
            <button
              type="button"
              onClick={handleClear}
              className="h-4 w-4 text-gray-400 hover:text-gray-600 transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 rounded"
              aria-label="Clear selection"
            >
              <X className="h-3 w-3" />
            </button>
          )}
        </div>
      </div>
      
      {isOpen && (
        <div
          ref={dropdownRef}
          className="absolute z-50 w-full mt-1 bg-white border border-gray-300 rounded-lg shadow-xl max-h-80 overflow-y-auto"
          role="listbox"
          aria-label="Airport search results"
        >
          {dropdownContent}
        </div>
      )}
      
      {error && (
        <p className="mt-1 text-sm text-red-600 flex items-center">
          <span className="mr-1">⚠</span>
          {error}
        </p>
      )}
    </div>
  );
};

export default AirportAutocomplete;
