import React, { useState, useEffect } from 'react';
import { Airport } from '../types/flight-filter';
import AirportAutocomplete from './AirportAutocomplete';
import MobileAirportAutocomplete from './MobileAirportAutocomplete';

interface ResponsiveAirportAutocompleteProps {
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
  forceMobile?: boolean;
  forceDesktop?: boolean;
}

const ResponsiveAirportAutocomplete: React.FC<ResponsiveAirportAutocompleteProps> = ({
  forceMobile = false,
  forceDesktop = false,
  ...props
}) => {
  const [isMobile, setIsMobile] = useState(false);

  useEffect(() => {
    const checkIsMobile = () => {
      // Check if we're on mobile based on screen size and touch capability
      const isMobileScreen = window.innerWidth < 768;
      const isTouchDevice = 'ontouchstart' in window || navigator.maxTouchPoints > 0;
      setIsMobile(isMobileScreen || isTouchDevice);
    };

    // Check on mount
    checkIsMobile();

    // Listen for resize events
    window.addEventListener('resize', checkIsMobile);
    
    return () => window.removeEventListener('resize', checkIsMobile);
  }, []);

  // Force specific version if requested
  if (forceMobile) {
    return <MobileAirportAutocomplete {...props} />;
  }
  
  if (forceDesktop) {
    return <AirportAutocomplete {...props} />;
  }

  // Use responsive logic
  if (isMobile) {
    return <MobileAirportAutocomplete {...props} />;
  }

  return <AirportAutocomplete {...props} />;
};

export default ResponsiveAirportAutocomplete;






