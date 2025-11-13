# Flight APIs Configuration
# This file configures multiple flight search providers with rate limiting and fallback strategies

Rails.application.config.after_initialize do
  # API Configuration for multiple providers
  FLIGHT_APIS_CONFIG = {
    # Skyscanner (Primary provider)
    skyscanner: {
      base_url: 'https://partners.api.skyscanner.net',
      api_key: ENV['SKYSCANNER_API_KEY'],
      rate_limit: {
        requests_per_minute: 50,
        requests_per_hour: 1000,
        burst_limit: 10
      },
      timeout: 30,
      retry_attempts: 3,
      fallback_priority: 1
    },

    # Amadeus (Professional flight search)
    amadeus: {
      base_url: 'https://test.api.amadeus.com', # Use production URL in production
      api_key: ENV['AMADEUS_API_KEY'],
      api_secret: ENV['AMADEUS_API_SECRET'],
      rate_limit: {
        requests_per_minute: 30,
        requests_per_hour: 500,
        burst_limit: 5
      },
      timeout: 45,
      retry_attempts: 3,
      fallback_priority: 2,
      requires_auth: true
    },

    # Google Flights (Price comparison and trends)
    google_flights: {
      base_url: 'https://www.googleapis.com/qpxExpress/v1',
      api_key: ENV['GOOGLE_FLIGHTS_API_KEY'],
      rate_limit: {
        requests_per_minute: 100,
        requests_per_hour: 10000,
        burst_limit: 20
      },
      timeout: 25,
      retry_attempts: 2,
      fallback_priority: 3
    },

    # Kiwi (Alternative provider)
    kiwi: {
      base_url: 'https://tequila-api.kiwi.com',
      api_key: ENV['KIWI_API_KEY'],
      rate_limit: {
        requests_per_minute: 40,
        requests_per_hour: 800,
        burst_limit: 8
      },
      timeout: 35,
      retry_attempts: 3,
      fallback_priority: 4
    }
  }.freeze

  # Global API settings
  FLIGHT_API_GLOBAL_CONFIG = {
    max_concurrent_requests: 10,
    request_timeout: 60,
    max_retry_attempts: 3,
    retry_delay_seconds: 5,
    cache_duration: 15.minutes,
    fallback_strategy: :cascade, # cascade, parallel, or priority
    data_quality_threshold: 0.8,
    duplicate_detection_enabled: true,
    price_validation_enabled: true,
    # Mock mode - set to true to use mock data instead of real APIs (no API keys needed)
    mock_mode: ENV['FLIGHT_API_MOCK_MODE'] == 'true' || Rails.env.development? && ENV['SKYSCANNER_API_KEY'].blank?,
    # Enable individual providers (useful for testing)
    enable_skyscanner: ENV['ENABLE_SKYSCANNER'] != 'false',
    enable_amadeus: ENV['ENABLE_AMADEUS'] != 'false',
    enable_google_flights: ENV['ENABLE_GOOGLE_FLIGHTS'] != 'false',
    enable_mock: ENV['ENABLE_MOCK'] != 'false'
  }.freeze

  # Currency conversion rates (updated daily)
  CURRENCY_CONVERSION = {
    USD: 1.0,
    EUR: 0.85,
    GBP: 0.73,
    CAD: 1.25,
    AUD: 1.35,
    JPY: 110.0,
    CNY: 6.45,
    INR: 75.0
  }.freeze

  # Airport code mappings for normalization
  AIRPORT_CODE_MAPPINGS = {
    # Common variations and aliases
    'NYC' => ['JFK', 'LGA', 'EWR'], # New York City
    'LON' => ['LHR', 'LGW', 'LCY', 'STN'], # London
    'PAR' => ['CDG', 'ORY', 'BVA'], # Paris
    'TYO' => ['NRT', 'HND'], # Tokyo
    'CHI' => ['ORD', 'MDW'], # Chicago
    'LAX' => ['LAX'], # Los Angeles
    'SFO' => ['SFO'], # San Francisco
    'MIA' => ['MIA'], # Miami
    'DFW' => ['DFW'], # Dallas/Fort Worth
    'ATL' => ['ATL']  # Atlanta
  }.freeze

  # Cabin class normalization
  CABIN_CLASS_MAPPING = {
    'economy' => ['economy', 'coach', 'Y', 'M', 'K', 'L', 'T', 'X'],
    'premium_economy' => ['premium_economy', 'premium', 'W', 'E', 'T'],
    'business' => ['business', 'C', 'D', 'J', 'Z', 'I'],
    'first' => ['first', 'F', 'A', 'P']
  }.freeze

  # Airline code mappings
  AIRLINE_CODE_MAPPING = {
    'AA' => 'American Airlines',
    'UA' => 'United Airlines',
    'DL' => 'Delta Air Lines',
    'WN' => 'Southwest Airlines',
    'BA' => 'British Airways',
    'LH' => 'Lufthansa',
    'AF' => 'Air France',
    'KL' => 'KLM Royal Dutch Airlines',
    'EK' => 'Emirates',
    'QR' => 'Qatar Airways',
    'TK' => 'Turkish Airlines',
    'SQ' => 'Singapore Airlines',
    'NH' => 'All Nippon Airways',
    'JL' => 'Japan Airlines',
    'CA' => 'Air China',
    'MU' => 'China Eastern Airlines',
    'CZ' => 'China Southern Airlines'
  }.freeze

  # Route validation rules
  ROUTE_VALIDATION_RULES = {
    max_distance_km: 20000, # Maximum reasonable flight distance
    min_distance_km: 50,     # Minimum reasonable flight distance
    invalid_combinations: [
      # Impossible or invalid route combinations
      { origin: 'HNL', destination: 'LAX', reason: 'Hawaii to mainland requires specific routing' },
      { origin: 'ANC', destination: 'MIA', reason: 'Alaska to Florida requires specific routing' }
    ],
    seasonal_routes: {
      # Routes that only operate during certain months
      'ANC-ICN' => { months: [5, 6, 7, 8], reason: 'Summer seasonal route' },
      'JNU-SEA' => { months: [5, 6, 7, 8, 9], reason: 'Summer seasonal route' }
    }
  }.freeze

  # Price validation rules
  PRICE_VALIDATION_RULES = {
    min_price_usd: 10,      # Minimum reasonable price
    max_price_usd: 10000,   # Maximum reasonable price
    price_variance_threshold: 0.5, # 50% variance from average
    suspicious_patterns: [
      'price_ends_in_999',   # Common pricing pattern
      'price_divisible_by_100', # Round pricing
      'price_too_low_for_route', # Unrealistically low prices
      'price_too_high_for_route' # Unrealistically high prices
    ]
  }.freeze
end





