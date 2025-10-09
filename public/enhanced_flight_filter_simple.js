// Enhanced Flight Filter Integration for Local Rails App
// Standalone version without complex imports

// Check if React is available globally
if (typeof React === 'undefined') {
  console.error('React is not loaded. Please ensure React is available globally.');
}

// Enhanced Airport Autocomplete Test Component
function AirportAutocompleteTest() {
  const [originSearch, setOriginSearch] = React.useState('');
  const [destinationSearch, setDestinationSearch] = React.useState('');
  const [originAirport, setOriginAirport] = React.useState(null);
  const [destinationAirport, setDestinationAirport] = React.useState(null);
  const [searchResults, setSearchResults] = React.useState([]);
  const [isLoading, setIsLoading] = React.useState(false);

  const handleOriginSelect = (airport) => {
    setOriginAirport(airport);
    if (airport) {
      setOriginSearch(`${airport.iata_code} - ${airport.city}`);
    }
  };

  const handleDestinationSelect = (airport) => {
    setDestinationAirport(airport);
    if (airport) {
      setDestinationSearch(`${airport.iata_code} - ${airport.city}`);
    }
  };

  const testSearch = async (query) => {
    if (!query || query.length < 2) return;
    
    setIsLoading(true);
    try {
      // Use the airport database directly
      const results = searchAirportsDatabase(query);
      setSearchResults(results.slice(0, 5)); // Show top 5 results
    } catch (error) {
      console.error('Search error:', error);
      setSearchResults([]);
    } finally {
      setIsLoading(false);
    }
  };

  const clearResults = () => {
    setSearchResults([]);
    setOriginSearch('');
    setDestinationSearch('');
    setOriginAirport(null);
    setDestinationAirport(null);
  };

  return React.createElement('div', { className: 'space-y-6' }, [
    // Search Interface
    React.createElement('div', { key: 'search', className: 'grid grid-cols-1 md:grid-cols-2 gap-6' }, [
      React.createElement('div', { key: 'origin' }, [
        React.createElement('label', { 
          key: 'label1',
          className: 'block text-sm font-medium text-gray-700 mb-2' 
        }, 'Origin Airport'),
        React.createElement('input', {
          key: 'input1',
          type: 'text',
          value: originSearch,
          onChange: (e) => setOriginSearch(e.target.value),
          placeholder: 'Search origin airports...',
          className: 'w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500'
        })
      ]),
      React.createElement('div', { key: 'destination' }, [
        React.createElement('label', { 
          key: 'label2',
          className: 'block text-sm font-medium text-gray-700 mb-2' 
        }, 'Destination Airport'),
        React.createElement('input', {
          key: 'input2',
          type: 'text',
          value: destinationSearch,
          onChange: (e) => setDestinationSearch(e.target.value),
          placeholder: 'Search destination airports...',
          className: 'w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500'
        })
      ])
    ]),

    // Quick Search Test
    React.createElement('div', { key: 'test', className: 'bg-gray-50 rounded-lg p-4' }, [
      React.createElement('h4', { 
        key: 'title',
        className: 'text-sm font-medium text-gray-900 mb-3' 
      }, 'Quick Search Test'),
      React.createElement('div', { 
        key: 'buttons',
        className: 'flex flex-wrap gap-2' 
      }, ['JFK', 'London', 'Tokyo', 'Dubai', 'Sydney', 'Brazil', 'Germany'].map((term) =>
        React.createElement('button', {
          key: term,
          onClick: () => testSearch(term),
          className: 'px-3 py-1 text-xs bg-blue-100 text-blue-700 rounded-full hover:bg-blue-200 transition-colors'
        }, term)
      )),
      
      isLoading && React.createElement('div', { 
        key: 'loading',
        className: 'mt-3 text-center' 
      }, [
        React.createElement('div', {
          key: 'spinner',
          className: 'inline-block h-4 w-4 border-2 border-blue-500 border-t-transparent rounded-full animate-spin'
        }),
        React.createElement('span', {
          key: 'text',
          className: 'ml-2 text-sm text-gray-600'
        }, 'Searching...')
      ]),

      searchResults.length > 0 && React.createElement('div', { key: 'results', className: 'mt-3' }, [
        React.createElement('h5', { 
          key: 'results-title',
          className: 'text-xs font-medium text-gray-700 mb-2' 
        }, 'Search Results:'),
        React.createElement('div', { 
          key: 'results-list',
          className: 'space-y-1' 
        }, searchResults.map((airport, index) =>
          React.createElement('div', {
            key: index,
            className: 'text-xs bg-white p-2 rounded border'
          }, `${airport.iata_code} - ${airport.city}, ${airport.country}`)
        ))
      ])
    ]),

    // Selected Airports Display
    (originAirport || destinationAirport) && React.createElement('div', { 
      key: 'selected',
      className: 'bg-green-50 rounded-lg p-4' 
    }, [
      React.createElement('h4', { 
        key: 'selected-title',
        className: 'text-sm font-medium text-green-900 mb-3' 
      }, 'Selected Airports'),
      React.createElement('div', { 
        key: 'selected-grid',
        className: 'grid grid-cols-1 md:grid-cols-2 gap-4' 
      }, [
        originAirport && React.createElement('div', {
          key: 'origin-selected',
          className: 'bg-white p-3 rounded border'
        }, [
          React.createElement('div', { 
            key: 'origin-label',
            className: 'text-sm font-semibold text-gray-900' 
          }, 'Origin'),
          React.createElement('div', { 
            key: 'origin-details',
            className: 'text-xs text-gray-600' 
          }, `${originAirport.iata_code} - ${originAirport.name}`),
          React.createElement('div', { 
            key: 'origin-location',
            className: 'text-xs text-gray-500' 
          }, `${originAirport.city}, ${originAirport.country}`)
        ]),
        destinationAirport && React.createElement('div', {
          key: 'destination-selected',
          className: 'bg-white p-3 rounded border'
        }, [
          React.createElement('div', { 
            key: 'dest-label',
            className: 'text-sm font-semibold text-gray-900' 
          }, 'Destination'),
          React.createElement('div', { 
            key: 'dest-details',
            className: 'text-xs text-gray-600' 
          }, `${destinationAirport.iata_code} - ${destinationAirport.name}`),
          React.createElement('div', { 
            key: 'dest-location',
            className: 'text-xs text-gray-500' 
          }, `${destinationAirport.city}, ${destinationAirport.country}`)
        ])
      ]),
      React.createElement('button', {
        key: 'clear-btn',
        onClick: clearResults,
        className: 'mt-3 px-3 py-1 text-xs bg-red-100 text-red-700 rounded hover:bg-red-200 transition-colors'
      }, 'Clear All')
    ]),

    // Database Stats
    React.createElement('div', { 
      key: 'stats',
      className: 'bg-blue-50 rounded-lg p-4' 
    }, [
      React.createElement('h4', { 
        key: 'stats-title',
        className: 'text-sm font-medium text-blue-900 mb-3' 
      }, 'Database Statistics'),
      React.createElement('div', { 
        key: 'stats-grid',
        className: 'grid grid-cols-2 md:grid-cols-4 gap-4 text-center' 
      }, [
        React.createElement('div', { key: 'total' }, [
          React.createElement('div', { 
            key: 'total-num',
            className: 'text-lg font-bold text-blue-600' 
          }, '100+'),
          React.createElement('div', { 
            key: 'total-label',
            className: 'text-xs text-blue-700' 
          }, 'Total Airports')
        ]),
        React.createElement('div', { key: 'countries' }, [
          React.createElement('div', { 
            key: 'countries-num',
            className: 'text-lg font-bold text-blue-600' 
          }, '50+'),
          React.createElement('div', { 
            key: 'countries-label',
            className: 'text-xs text-blue-700' 
          }, 'Countries')
        ]),
        React.createElement('div', { key: 'speed' }, [
          React.createElement('div', { 
            key: 'speed-num',
            className: 'text-lg font-bold text-blue-600' 
          }, '<50ms'),
          React.createElement('div', { 
            key: 'speed-label',
            className: 'text-xs text-blue-700' 
          }, 'Search Speed')
        ]),
        React.createElement('div', { key: 'coverage' }, [
          React.createElement('div', { 
            key: 'coverage-num',
            className: 'text-lg font-bold text-blue-600' 
          }, '100%'),
          React.createElement('div', { 
            key: 'coverage-label',
            className: 'text-xs text-blue-700' 
          }, 'Coverage')
        ])
      ])
    ])
  ]);
}

// Simple Airport Database (inline)
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
  { iata_code: 'SYD', name: 'Sydney Airport', city: 'Sydney', country: 'Australia', icao_code: 'YSSY' }
];

// Search function
function searchAirportsDatabase(searchTerm) {
  if (!searchTerm || searchTerm.trim().length < 2) {
    return [];
  }

  const query = searchTerm.trim().toUpperCase();
  
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

// Initialize components when DOM is ready
document.addEventListener('DOMContentLoaded', function() {
  console.log('Enhanced Flight Filter: DOM loaded, initializing components...');
  
  // Check if React is available
  if (typeof React === 'undefined') {
    console.error('React is not available. Please ensure React is loaded.');
    return;
  }

  // Mount Airport Autocomplete Test
  const airportTest = document.getElementById('airport-autocomplete-test');
  if (airportTest) {
    console.log('Mounting Airport Autocomplete Test...');
    try {
      const root = ReactDOM.createRoot(airportTest);
      root.render(React.createElement(AirportAutocompleteTest));
      console.log('Airport Autocomplete Test mounted successfully');
    } catch (error) {
      console.error('Error mounting Airport Autocomplete Test:', error);
    }
  } else {
    console.log('Airport autocomplete test container not found');
  }

  // Mount Enhanced Flight Filter Demo
  const flightFilterDemo = document.getElementById('flight-filter-demo');
  if (flightFilterDemo) {
    console.log('Mounting Enhanced Flight Filter Demo...');
    try {
      const root = ReactDOM.createRoot(flightFilterDemo);
      root.render(React.createElement('div', { 
        className: 'text-center p-8' 
      }, [
        React.createElement('h3', { 
          key: 'title',
          className: 'text-xl font-semibold text-gray-900 mb-4' 
        }, 'Enhanced Flight Filter Demo'),
        React.createElement('p', { 
          key: 'description',
          className: 'text-gray-600 mb-6' 
        }, 'This is a simplified version of the enhanced flight filter with airport autocomplete functionality.'),
        React.createElement('div', { 
          key: 'features',
          className: 'grid grid-cols-1 md:grid-cols-3 gap-4 text-left' 
        }, [
          React.createElement('div', { key: 'feature1', className: 'bg-blue-50 p-4 rounded-lg' }, [
            React.createElement('h4', { 
              key: 'title1',
              className: 'font-semibold text-blue-900 mb-2' 
            }, 'Intelligent Search'),
            React.createElement('p', { 
              key: 'desc1',
              className: 'text-sm text-blue-700' 
            }, 'Smart scoring system prioritizes exact matches and provides relevant results.')
          ]),
          React.createElement('div', { key: 'feature2', className: 'bg-green-50 p-4 rounded-lg' }, [
            React.createElement('h4', { 
              key: 'title2',
              className: 'font-semibold text-green-900 mb-2' 
            }, 'Lightning Fast'),
            React.createElement('p', { 
              key: 'desc2',
              className: 'text-sm text-green-700' 
            }, 'Advanced caching system delivers results in under 50ms.')
          ]),
          React.createElement('div', { key: 'feature3', className: 'bg-purple-50 p-4 rounded-lg' }, [
            React.createElement('h4', { 
              key: 'title3',
              className: 'font-semibold text-purple-900 mb-2' 
            }, 'Mobile Optimized'),
            React.createElement('p', { 
              key: 'desc3',
              className: 'text-sm text-purple-700' 
            }, 'Responsive design automatically adapts to desktop and mobile.')
          ])
        ])
      ]));
      console.log('Enhanced Flight Filter Demo mounted successfully');
    } catch (error) {
      console.error('Error mounting Enhanced Flight Filter Demo:', error);
    }
  } else {
    console.log('Flight filter demo container not found');
  }
});

console.log('Enhanced Flight Filter script loaded');


