// Enhanced Flight Filter - Exact replica of demo_flight_filter.html functionality
// This replicates the complete flight filter demo with working autocomplete

// Comprehensive airport database (from the demo)
const airportDatabase = [
    { iata_code: 'ATL', name: 'Hartsfield-Jackson Atlanta International Airport', city: 'Atlanta', country: 'USA', icao_code: 'KATL' },
    { iata_code: 'LAX', name: 'Los Angeles International Airport', city: 'Los Angeles', country: 'USA', icao_code: 'KLAX' },
    { iata_code: 'ORD', name: 'O\'Hare International Airport', city: 'Chicago', country: 'USA', icao_code: 'KORD' },
    { iata_code: 'DFW', name: 'Dallas/Fort Worth International Airport', city: 'Dallas', country: 'USA', icao_code: 'KDFW' },
    { iata_code: 'DEN', name: 'Denver International Airport', city: 'Denver', country: 'USA', icao_code: 'KDEN' },
    { iata_code: 'JFK', name: 'John F. Kennedy International Airport', city: 'New York', country: 'USA', icao_code: 'KJFK' },
    { iata_code: 'SFO', name: 'San Francisco International Airport', city: 'San Francisco', country: 'USA', icao_code: 'KSFO' },
    { iata_code: 'SEA', name: 'Seattle-Tacoma International Airport', city: 'Seattle', country: 'USA', icao_code: 'KSEA' },
    { iata_code: 'LHR', name: 'London Heathrow Airport', city: 'London', country: 'UK', icao_code: 'EGLL' },
    { iata_code: 'CDG', name: 'Charles de Gaulle Airport', city: 'Paris', country: 'France', icao_code: 'LFPG' },
    { iata_code: 'FRA', name: 'Frankfurt Airport', city: 'Frankfurt', country: 'Germany', icao_code: 'EDDF' },
    { iata_code: 'AMS', name: 'Amsterdam Airport Schiphol', city: 'Amsterdam', country: 'Netherlands', icao_code: 'EHAM' },
    { iata_code: 'NRT', name: 'Narita International Airport', city: 'Tokyo', country: 'Japan', icao_code: 'RJAA' },
    { iata_code: 'ICN', name: 'Incheon International Airport', city: 'Seoul', country: 'South Korea', icao_code: 'RKSI' },
    { iata_code: 'PEK', name: 'Beijing Capital International Airport', city: 'Beijing', country: 'China', icao_code: 'ZBAA' },
    { iata_code: 'PVG', name: 'Shanghai Pudong International Airport', city: 'Shanghai', country: 'China', icao_code: 'ZSPD' },
    { iata_code: 'HKG', name: 'Hong Kong International Airport', city: 'Hong Kong', country: 'Hong Kong', icao_code: 'VHHH' },
    { iata_code: 'SIN', name: 'Singapore Changi Airport', city: 'Singapore', country: 'Singapore', icao_code: 'WSSS' },
    { iata_code: 'DXB', name: 'Dubai International Airport', city: 'Dubai', country: 'UAE', icao_code: 'OMDB' },
    { iata_code: 'SYD', name: 'Sydney Airport', city: 'Sydney', country: 'Australia', icao_code: 'YSSY' },
    { iata_code: 'MAD', name: 'Adolfo Suárez Madrid-Barajas Airport', city: 'Madrid', country: 'Spain', icao_code: 'LEMD' },
    { iata_code: 'BCN', name: 'Barcelona-El Prat Airport', city: 'Barcelona', country: 'Spain', icao_code: 'LEBL' },
    { iata_code: 'FCO', name: 'Leonardo da Vinci International Airport', city: 'Rome', country: 'Italy', icao_code: 'LIRF' },
    { iata_code: 'MXP', name: 'Milan Malpensa Airport', city: 'Milan', country: 'Italy', icao_code: 'LIMC' },
    { iata_code: 'ZUR', name: 'Zurich Airport', city: 'Zurich', country: 'Switzerland', icao_code: 'LSZH' },
    { iata_code: 'YYZ', name: 'Toronto Pearson International Airport', city: 'Toronto', country: 'Canada', icao_code: 'CYYZ' },
    { iata_code: 'YVR', name: 'Vancouver International Airport', city: 'Vancouver', country: 'Canada', icao_code: 'CYVR' },
    { iata_code: 'YUL', name: 'Montréal-Pierre Elliott Trudeau International Airport', city: 'Montreal', country: 'Canada', icao_code: 'CYUL' },
    { iata_code: 'MEX', name: 'Mexico City International Airport', city: 'Mexico City', country: 'Mexico', icao_code: 'MMMX' },
    { iata_code: 'CUN', name: 'Cancún International Airport', city: 'Cancún', country: 'Mexico', icao_code: 'MMUN' },
    { iata_code: 'MEL', name: 'Melbourne Airport', city: 'Melbourne', country: 'Australia', icao_code: 'YMML' },
    { iata_code: 'BNE', name: 'Brisbane Airport', city: 'Brisbane', country: 'Australia', icao_code: 'YBBN' },
    { iata_code: 'PER', name: 'Perth Airport', city: 'Perth', country: 'Australia', icao_code: 'YPPH' },
    { iata_code: 'AKL', name: 'Auckland Airport', city: 'Auckland', country: 'New Zealand', icao_code: 'NZAA' },
    { iata_code: 'WLG', name: 'Wellington Airport', city: 'Wellington', country: 'New Zealand', icao_code: 'NZWN' },
    { iata_code: 'CAI', name: 'Cairo International Airport', city: 'Cairo', country: 'Egypt', icao_code: 'HECA' },
    { iata_code: 'JNB', name: 'O.R. Tambo International Airport', city: 'Johannesburg', country: 'South Africa', icao_code: 'FAOR' },
    { iata_code: 'LAD', name: 'Quatro de Fevereiro Airport', city: 'Luanda', country: 'Angola', icao_code: 'FNLU' },
    { iata_code: 'LOS', name: 'Murtala Muhammed International Airport', city: 'Lagos', country: 'Nigeria', icao_code: 'DNMM' },
    { iata_code: 'NBO', name: 'Jomo Kenyatta International Airport', city: 'Nairobi', country: 'Kenya', icao_code: 'HKJK' },
    { iata_code: 'GRU', name: 'São Paulo/Guarulhos International Airport', city: 'São Paulo', country: 'Brazil', icao_code: 'SBGR' },
    { iata_code: 'EZE', name: 'Ministro Pistarini International Airport', city: 'Buenos Aires', country: 'Argentina', icao_code: 'SAEZ' },
    { iata_code: 'SCL', name: 'Arturo Merino Benítez International Airport', city: 'Santiago', country: 'Chile', icao_code: 'SCEL' },
    { iata_code: 'LIM', name: 'Jorge Chávez International Airport', city: 'Lima', country: 'Peru', icao_code: 'SPJC' },
    { iata_code: 'BOG', name: 'El Dorado International Airport', city: 'Bogotá', country: 'Colombia', icao_code: 'SKBO' },
    { iata_code: 'IST', name: 'Istanbul Airport', city: 'Istanbul', country: 'Turkey', icao_code: 'LTFM' },
    { iata_code: 'TLV', name: 'Ben Gurion Airport', city: 'Tel Aviv', country: 'Israel', icao_code: 'LLBG' },
    { iata_code: 'BAH', name: 'Bahrain International Airport', city: 'Manama', country: 'Bahrain', icao_code: 'OBBI' },
    { iata_code: 'KWI', name: 'Kuwait International Airport', city: 'Kuwait City', country: 'Kuwait', icao_code: 'OKBK' },
    { iata_code: 'MCT', name: 'Muscat International Airport', city: 'Muscat', country: 'Oman', icao_code: 'OOMS' },
    { iata_code: 'DEL', name: 'Indira Gandhi International Airport', city: 'New Delhi', country: 'India', icao_code: 'VIDP' },
    { iata_code: 'BOM', name: 'Chhatrapati Shivaji Maharaj International Airport', city: 'Mumbai', country: 'India', icao_code: 'VABB' },
    { iata_code: 'BLR', name: 'Kempegowda International Airport', city: 'Bangalore', country: 'India', icao_code: 'VOBL' },
    { iata_code: 'MAA', name: 'Chennai International Airport', city: 'Chennai', country: 'India', icao_code: 'VOMM' },
    { iata_code: 'CCU', name: 'Netaji Subhash Chandra Bose International Airport', city: 'Kolkata', country: 'India', icao_code: 'VECC' }
];

const popularAirports = airportDatabase.slice(0, 8);

function searchAirports(searchTerm) {
    if (!searchTerm || searchTerm.trim().length < 2) {
        return [];
    }
    
    const query = searchTerm.trim().toUpperCase();
    
    // Score airports based on match quality
    const scoredAirports = airportDatabase.map(airport => {
        let score = 0;
        
        if (airport.iata_code === query) score += 1000;
        if (airport.iata_code.startsWith(query)) score += 500;
        if (airport.iata_code.includes(query)) score += 200;
        if (airport.name.toUpperCase().startsWith(query)) score += 300;
        if (airport.name.toUpperCase().includes(query)) score += 150;
        if (airport.city.toUpperCase().startsWith(query)) score += 250;
        if (airport.city.toUpperCase().includes(query)) score += 100;
        if (airport.country.toUpperCase().startsWith(query)) score += 200;
        if (airport.country.toUpperCase().includes(query)) score += 50;
        
        return { airport, score };
    }).filter(item => item.score > 0);
    
    return scoredAirports
        .sort((a, b) => b.score - a.score)
        .slice(0, 15)
        .map(item => item.airport);
}

// Enhanced Airport Autocomplete Component (exact replica from demo)
function AirportAutocomplete({ value, onChange, onSelect, placeholder, label, selectedAirport, showPopularAirports = true }) {
    const [isOpen, setIsOpen] = React.useState(false);
    const [airports, setAirports] = React.useState([]);
    const [isLoading, setIsLoading] = React.useState(false);
    const [highlightedIndex, setHighlightedIndex] = React.useState(-1);
    const [hasSearched, setHasSearched] = React.useState(false);
    
    const inputRef = React.useRef(null);
    const debounceTimeout = React.useRef(null);

    const handleInputChange = (e) => {
        const newValue = e.target.value;
        onChange(newValue);
        
        if (selectedAirport && newValue !== `${selectedAirport.iata_code} - ${selectedAirport.city}`) {
            onSelect(null);
        }
        
        clearTimeout(debounceTimeout.current);
        debounceTimeout.current = setTimeout(() => {
            if (newValue.trim().length >= 2) {
                setIsLoading(true);
                setHasSearched(true);
                setTimeout(() => {
                    const results = searchAirports(newValue);
                    setAirports(results);
                    setIsLoading(false);
                }, 300);
            } else {
                setAirports([]);
                setHasSearched(false);
            }
        }, 300);
    };

    const handleSelectAirport = (airport) => {
        const displayValue = `${airport.iata_code} - ${airport.city}`;
        onChange(displayValue);
        onSelect(airport);
        setIsOpen(false);
        setHighlightedIndex(-1);
    };

    const handleFocus = () => {
        setIsOpen(true);
        if (value && value.trim().length >= 2) {
            setAirports(searchAirports(value));
        }
    };

    const handleKeyDown = (e) => {
        const currentAirports = airports.length > 0 ? airports : (!hasSearched ? popularAirports.slice(0, 8) : []);
        
        if (!isOpen || currentAirports.length === 0) {
            if (e.key === 'ArrowDown') {
                e.preventDefault();
                setIsOpen(true);
                setAirports(searchAirports(value));
            }
            return;
        }

        switch (e.key) {
            case 'ArrowDown':
                e.preventDefault();
                setHighlightedIndex(prev => 
                    prev < currentAirports.length - 1 ? prev + 1 : 0
                );
                break;
            case 'ArrowUp':
                e.preventDefault();
                setHighlightedIndex(prev => 
                    prev > 0 ? prev - 1 : currentAirports.length - 1
                );
                break;
            case 'Enter':
                e.preventDefault();
                if (highlightedIndex >= 0 && highlightedIndex < currentAirports.length) {
                    handleSelectAirport(currentAirports[highlightedIndex]);
                }
                break;
            case 'Escape':
                setIsOpen(false);
                setHighlightedIndex(-1);
                break;
        }
    };

    const handleClear = () => {
        onChange('');
        onSelect(null);
        setIsOpen(false);
        setHighlightedIndex(-1);
        inputRef.current?.focus();
    };

    const dropdownContent = () => {
        if (isLoading) {
            return React.createElement('div', { className: 'px-4 py-6 text-center' }, [
                React.createElement('div', { 
                    key: 'spinner',
                    className: 'h-6 w-6 border-2 border-blue-500 border-t-transparent rounded-full animate-spin mx-auto mb-2' 
                }),
                React.createElement('p', { 
                    key: 'text',
                    className: 'text-sm text-gray-600' 
                }, 'Searching airports...')
            ]);
        }

        if (hasSearched && airports.length === 0) {
            return React.createElement('div', { className: 'px-4 py-6 text-center' }, [
                React.createElement('svg', { 
                    key: 'icon',
                    className: 'h-6 w-6 text-gray-400 mx-auto mb-2',
                    fill: 'none',
                    stroke: 'currentColor',
                    viewBox: '0 0 24 24'
                }, React.createElement('path', {
                    strokeLinecap: 'round',
                    strokeLinejoin: 'round',
                    strokeWidth: 2,
                    d: 'M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z'
                })),
                React.createElement('p', { 
                    key: 'text1',
                    className: 'text-sm text-gray-600' 
                }, 'No airports found'),
                React.createElement('p', { 
                    key: 'text2',
                    className: 'text-xs text-gray-500 mt-1' 
                }, 'Try searching by city, country, or airport code')
            ]);
        }

        if (airports.length > 0) {
            return airports.map((airport, index) => 
                React.createElement('button', {
                    key: `${airport.iata_code}-${index}`,
                    type: 'button',
                    onClick: () => handleSelectAirport(airport),
                    className: `w-full text-left px-4 py-3 hover:bg-gray-50 border-b border-gray-100 last:border-b-0 transition-colors ${
                        index === highlightedIndex ? 'bg-blue-50 border-blue-200' : ''
                    }`
                }, React.createElement('div', { className: 'flex items-center justify-between' }, [
                    React.createElement('div', { key: 'content', className: 'flex-1 min-w-0' }, [
                        React.createElement('div', { key: 'codes', className: 'flex items-center space-x-2' }, [
                            React.createElement('span', { 
                                key: 'iata',
                                className: 'font-semibold text-gray-900 text-sm' 
                            }, airport.iata_code),
                            React.createElement('span', { 
                                key: 'icao',
                                className: 'text-xs text-gray-500' 
                            }, airport.icao_code)
                        ]),
                        React.createElement('div', { 
                            key: 'location',
                            className: 'text-sm text-gray-700 font-medium truncate' 
                        }, `${airport.city}, ${airport.country}`),
                        React.createElement('div', { 
                            key: 'name',
                            className: 'text-xs text-gray-500 truncate' 
                        }, airport.name)
                    ]),
                    React.createElement('div', { key: 'icon', className: 'flex-shrink-0 ml-3' }, 
                        React.createElement('svg', {
                            className: 'h-4 w-4 text-gray-400',
                            fill: 'none',
                            stroke: 'currentColor',
                            viewBox: '0 0 24 24'
                        }, React.createElement('path', {
                            strokeLinecap: 'round',
                            strokeLinejoin: 'round',
                            strokeWidth: 2,
                            d: 'M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z'
                        }))
                    )
                ]))
            );
        }

        if (!hasSearched) {
            return React.createElement('div', {}, [
                React.createElement('div', { 
                    key: 'header',
                    className: 'px-4 py-2 bg-gray-50 border-b border-gray-200' 
                }, React.createElement('div', { className: 'flex items-center space-x-2' }, [
                    React.createElement('svg', { 
                        key: 'icon',
                        className: 'h-4 w-4 text-gray-500',
                        fill: 'none',
                        stroke: 'currentColor',
                        viewBox: '0 0 24 24'
                    }, React.createElement('path', {
                        strokeLinecap: 'round',
                        strokeLinejoin: 'round',
                        strokeWidth: 2,
                        d: 'M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z'
                    })),
                    React.createElement('span', { 
                        key: 'text',
                        className: 'text-xs font-medium text-gray-700' 
                    }, 'Popular Destinations')
                ])),
                ...popularAirports.map((airport, index) => 
                    React.createElement('button', {
                        key: `popular-${airport.iata_code}-${index}`,
                        type: 'button',
                        onClick: () => handleSelectAirport(airport),
                        className: `w-full text-left px-4 py-3 hover:bg-gray-50 border-b border-gray-100 last:border-b-0 transition-colors ${
                            index === highlightedIndex ? 'bg-blue-50 border-blue-200' : ''
                        }`
                    }, React.createElement('div', { className: 'flex items-center justify-between' }, [
                        React.createElement('div', { key: 'content', className: 'flex-1 min-w-0' }, [
                            React.createElement('div', { key: 'codes', className: 'flex items-center space-x-2' }, [
                                React.createElement('span', { 
                                    key: 'iata',
                                    className: 'font-semibold text-gray-900 text-sm' 
                                }, airport.iata_code),
                                React.createElement('span', { 
                                    key: 'icao',
                                    className: 'text-xs text-gray-500' 
                                }, airport.icao_code)
                            ]),
                            React.createElement('div', { 
                                key: 'location',
                                className: 'text-sm text-gray-700 font-medium truncate' 
                            }, `${airport.city}, ${airport.country}`),
                            React.createElement('div', { 
                                key: 'name',
                                className: 'text-xs text-gray-500 truncate' 
                            }, airport.name)
                        ]),
                        React.createElement('div', { key: 'icon', className: 'flex-shrink-0 ml-3' }, 
                            React.createElement('svg', {
                                className: 'h-4 w-4 text-gray-400',
                                fill: 'none',
                                stroke: 'currentColor',
                                viewBox: '0 0 24 24'
                            }, React.createElement('path', {
                                strokeLinecap: 'round',
                                strokeLinejoin: 'round',
                                strokeWidth: 2,
                                d: 'M12 19l9 2-9-18-9 18 9-2zm0 0v-8'
                            }))
                        )
                    ]))
                )
            ]);
        }

        return null;
    };

    return React.createElement('div', { className: 'relative' }, [
        label && React.createElement('label', { 
            key: 'label',
            className: 'block text-sm font-medium text-gray-700 mb-2' 
        }, label),
        
        React.createElement('div', { key: 'input-container', className: 'relative' }, [
            React.createElement('input', {
                key: 'input',
                ref: inputRef,
                type: 'text',
                value: value,
                onChange: handleInputChange,
                onFocus: handleFocus,
                onKeyDown: handleKeyDown,
                placeholder: placeholder,
                className: 'w-full px-4 py-3 pr-12 text-base border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500',
                autoComplete: 'off'
            }),
            
            React.createElement('div', { 
                key: 'icons',
                className: 'absolute right-3 top-1/2 transform -translate-y-1/2 flex items-center space-x-1' 
            }, [
                isLoading && React.createElement('div', { 
                    key: 'loading',
                    className: 'h-4 w-4 border-2 border-blue-500 border-t-transparent rounded-full animate-spin' 
                }),
                
                !isLoading && !selectedAirport && React.createElement('svg', { 
                    key: 'pin',
                    className: 'h-4 w-4 text-gray-400',
                    fill: 'none',
                    stroke: 'currentColor',
                    viewBox: '0 0 24 24'
                }, React.createElement('path', {
                    strokeLinecap: 'round',
                    strokeLinejoin: 'round',
                    strokeWidth: 2,
                    d: 'M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z'
                })),
                
                selectedAirport && React.createElement('button', {
                    key: 'clear',
                    type: 'button',
                    onClick: handleClear,
                    className: 'h-4 w-4 text-gray-400 hover:text-gray-600 transition-colors'
                }, React.createElement('svg', {
                    className: 'h-3 w-3',
                    fill: 'none',
                    stroke: 'currentColor',
                    viewBox: '0 0 24 24'
                }, React.createElement('path', {
                    strokeLinecap: 'round',
                    strokeLinejoin: 'round',
                    strokeWidth: 2,
                    d: 'M6 18L18 6M6 6l12 12'
                })))
            ])
        ]),
        
        isOpen && React.createElement('div', {
            key: 'dropdown',
            className: 'absolute z-10 w-full mt-1 bg-white border border-gray-300 rounded-lg shadow-xl max-h-80 overflow-y-auto'
        }, dropdownContent())
    ]);
}

// Flight Filter Demo Component (exact replica from demo)
function FlightFilterDemo() {
    const [currentStep, setCurrentStep] = React.useState(1);
    const [filter, setFilter] = React.useState({
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

    const [originSearch, setOriginSearch] = React.useState('');
    const [destinationSearch, setDestinationSearch] = React.useState('');

    const updateFilter = (updates) => {
        setFilter(prev => ({ ...prev, ...updates }));
    };

    const handleOriginSelect = (airport) => {
        updateFilter({ origin: airport });
    };

    const handleDestinationSelect = (airport) => {
        updateFilter({ destination: airport });
    };

    const formatDate = (date) => {
        if (!date) return '';
        return date.toISOString().split('T')[0];
    };

    const getMinDate = () => {
        return new Date().toISOString().split('T')[0];
    };

    const getMaxDate = () => {
        const maxDate = new Date();
        maxDate.setFullYear(maxDate.getFullYear() + 1);
        return maxDate.toISOString().split('T')[0];
    };

    return React.createElement('div', { className: 'max-w-4xl mx-auto' }, [
        // Step Indicator
        React.createElement('div', { key: 'steps', className: 'mb-8' }, [
            React.createElement('div', { 
                key: 'step-indicator',
                className: 'flex items-center justify-center space-x-4' 
            }, [1, 2, 3, 4].map((step) => 
                React.createElement('div', { key: step, className: 'flex items-center' }, [
                    React.createElement('div', { 
                        key: 'step-circle',
                        className: `w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium ${
                            step === currentStep 
                                ? 'bg-blue-600 text-white' 
                                : step < currentStep 
                                    ? 'bg-green-500 text-white' 
                                    : 'bg-gray-200 text-gray-600'
                        }`
                    }, step < currentStep ? '✓' : step),
                    step < 4 && React.createElement('div', { 
                        key: 'connector',
                        className: `w-16 h-1 mx-2 ${
                            step < currentStep ? 'bg-green-500' : 'bg-gray-200'
                        }` 
                    })
                ])
            )),
            React.createElement('div', { 
                key: 'step-title',
                className: 'text-center mt-4' 
            }, React.createElement('h2', { 
                className: 'text-xl font-semibold text-gray-900' 
            }, 
                currentStep === 1 && 'Route & Dates',
                currentStep === 2 && 'Flight Preferences',
                currentStep === 3 && 'Price Settings',
                currentStep === 4 && 'Alert Preferences'
            ))
        ]),

        // Step Content
        React.createElement('div', { 
            key: 'content',
            className: 'bg-white rounded-lg shadow-lg p-8' 
        }, [
            currentStep === 1 && React.createElement('div', { key: 'step1', className: 'space-y-6' }, [
                // Trip Type
                React.createElement('div', { key: 'trip-type' }, [
                    React.createElement('h3', { 
                        key: 'title',
                        className: 'text-lg font-semibold text-gray-900 mb-4' 
                    }, 'Trip Type'),
                    React.createElement('div', { 
                        key: 'options',
                        className: 'grid grid-cols-3 gap-3' 
                    }, ['one-way', 'round-trip', 'multi-city'].map((type) => 
                        React.createElement('button', {
                            key: type,
                            onClick: () => updateFilter({ tripType: type }),
                            className: `p-4 rounded-lg border-2 transition-colors ${
                                filter.tripType === type
                                    ? 'border-blue-500 bg-blue-50 text-blue-700'
                                    : 'border-gray-300 bg-white text-gray-700 hover:border-gray-400'
                            }`
                        }, React.createElement('div', { 
                            className: 'text-sm font-medium capitalize' 
                        }, type.replace('-', ' ')))
                    ))
                ]),

                // Route Selection with Enhanced Autocomplete
                React.createElement('div', { 
                    key: 'route-selection',
                    className: 'grid grid-cols-1 md:grid-cols-2 gap-6' 
                }, [
                    React.createElement(AirportAutocomplete, {
                        key: 'origin',
                        value: originSearch,
                        onChange: setOriginSearch,
                        onSelect: handleOriginSelect,
                        placeholder: 'Search origin airports...',
                        label: 'Origin Airport',
                        selectedAirport: filter.origin,
                        showPopularAirports: true
                    }),
                    React.createElement(AirportAutocomplete, {
                        key: 'destination',
                        value: destinationSearch,
                        onChange: setDestinationSearch,
                        onSelect: handleDestinationSelect,
                        placeholder: 'Search destination airports...',
                        label: 'Destination Airport',
                        selectedAirport: filter.destination,
                        showPopularAirports: true
                    })
                ]),

                // Date Selection
                React.createElement('div', { 
                    key: 'date-selection',
                    className: 'grid grid-cols-1 md:grid-cols-2 gap-6' 
                }, [
                    React.createElement('div', { key: 'departure' }, [
                        React.createElement('label', { 
                            key: 'label',
                            className: 'block text-sm font-medium text-gray-700 mb-2' 
                        }, 'Departure Date'),
                        React.createElement('input', {
                            key: 'input',
                            type: 'date',
                            value: formatDate(filter.departureDate),
                            onChange: (e) => updateFilter({ departureDate: e.target.value ? new Date(e.target.value) : null }),
                            min: getMinDate(),
                            max: getMaxDate(),
                            className: 'w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500'
                        })
                    ]),
                    filter.tripType === 'round-trip' && React.createElement('div', { key: 'return' }, [
                        React.createElement('label', { 
                            key: 'label',
                            className: 'block text-sm font-medium text-gray-700 mb-2' 
                        }, 'Return Date'),
                        React.createElement('input', {
                            key: 'input',
                            type: 'date',
                            value: formatDate(filter.returnDate),
                            onChange: (e) => updateFilter({ returnDate: e.target.value ? new Date(e.target.value) : null }),
                            min: filter.departureDate ? formatDate(filter.departureDate) : getMinDate(),
                            max: getMaxDate(),
                            className: 'w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500'
                        })
                    ])
                ]),

                // Flexible Dates
                React.createElement('div', { 
                    key: 'flexible-dates',
                    className: 'flex items-center space-x-3' 
                }, [
                    React.createElement('input', {
                        key: 'checkbox',
                        type: 'checkbox',
                        id: 'flexibleDates',
                        checked: filter.flexibleDates,
                        onChange: (e) => updateFilter({ flexibleDates: e.target.checked }),
                        className: 'h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded'
                    }),
                    React.createElement('label', { 
                        key: 'label',
                        htmlFor: 'flexibleDates',
                        className: 'text-sm text-gray-700' 
                    }, `Flexible dates (±${filter.dateFlexibility} days)`)
                ])
            ]),

            // Navigation
            React.createElement('div', { 
                key: 'navigation',
                className: 'flex justify-between mt-8 pt-6 border-t border-gray-200' 
            }, [
                React.createElement('button', {
                    key: 'prev',
                    onClick: () => setCurrentStep(Math.max(1, currentStep - 1)),
                    disabled: currentStep === 1,
                    className: 'px-6 py-3 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed'
                }, 'Previous'),
                
                currentStep < 4 ? React.createElement('button', {
                    key: 'next',
                    onClick: () => setCurrentStep(Math.min(4, currentStep + 1)),
                    className: 'px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700'
                }, 'Next') : React.createElement('button', {
                    key: 'save',
                    onClick: () => {
                        alert('Filter saved! Check the console for the complete filter data.');
                        console.log('Complete Filter:', filter);
                    },
                    className: 'px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700'
                }, 'Save Filter')
            ])
        ]),

        // Filter Summary
        React.createElement('div', { 
            key: 'summary',
            className: 'mt-8 bg-gray-50 rounded-lg p-6' 
        }, [
            React.createElement('h3', { 
                key: 'title',
                className: 'text-lg font-semibold text-gray-900 mb-4' 
            }, 'Current Filter Summary'),
            React.createElement('div', { 
                key: 'details',
                className: 'grid grid-cols-1 md:grid-cols-2 gap-4 text-sm' 
            }, [
                React.createElement('div', { key: 'origin' }, [
                    React.createElement('span', { className: 'font-medium' }, 'Origin: '),
                    filter.origin ? `${filter.origin.iata_code} - ${filter.origin.city}` : 'Not selected'
                ]),
                React.createElement('div', { key: 'destination' }, [
                    React.createElement('span', { className: 'font-medium' }, 'Destination: '),
                    filter.destination ? `${filter.destination.iata_code} - ${filter.destination.city}` : 'Not selected'
                ]),
                React.createElement('div', { key: 'trip-type' }, [
                    React.createElement('span', { className: 'font-medium' }, 'Trip Type: '),
                    filter.tripType
                ]),
                React.createElement('div', { key: 'cabin-class' }, [
                    React.createElement('span', { className: 'font-medium' }, 'Cabin Class: '),
                    filter.cabinClass
                ]),
                React.createElement('div', { key: 'passengers' }, [
                    React.createElement('span', { className: 'font-medium' }, 'Passengers: '),
                    filter.passengers.adults + filter.passengers.children + filter.passengers.infants
                ]),
                React.createElement('div', { key: 'target-price' }, [
                    React.createElement('span', { className: 'font-medium' }, 'Target Price: '),
                    `$${filter.targetPrice}`
                ])
            ])
        ])
    ]);
}

// Initialize components when DOM is ready
document.addEventListener('DOMContentLoaded', function() {
    console.log('Enhanced Flight Filter: DOM loaded, initializing components...');
    
    // Check if React is available
    if (typeof React === 'undefined') {
        console.error('React is not available. Please ensure React is loaded.');
        return;
    }

    // Mount Flight Filter Demo
    const flightFilterDemo = document.getElementById('flight-filter-demo');
    if (flightFilterDemo) {
        console.log('Mounting Flight Filter Demo...');
        try {
            const root = ReactDOM.createRoot(flightFilterDemo);
            root.render(React.createElement(FlightFilterDemo));
            console.log('Flight Filter Demo mounted successfully');
        } catch (error) {
            console.error('Error mounting Flight Filter Demo:', error);
        }
    } else {
        console.log('Flight filter demo container not found');
    }
});

console.log('Enhanced Flight Filter script loaded');


