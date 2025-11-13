module FlightApis
  class MockService < BaseApiService
    # Mock service for testing without API keys
    # Generates realistic flight data based on route and parameters
    
    def initialize
      super
      @mock_data_cache = {}
    end

    def search_flights(params = {})
      # Generate realistic mock flight data
      origin = params[:origin] || params[:origin_airport] || 'JFK'
      destination = params[:destination] || params[:destination_airport] || 'LAX'
      departure_date = params[:outbound_date] || params[:departure_date] || (Date.today + 30.days).strftime('%Y-%m-%d')
      return_date = params[:inbound_date] || params[:return_date]
      adults = params[:adults] || params[:passengers] || 1
      cabin_class = params[:cabin_class] || 'economy'
      
      flights = []
      
      # Generate 10-20 flights for variety
      flight_count = rand(10..20)
      
      flight_count.times do |i|
        base_price = calculate_base_price(origin, destination, cabin_class)
        price = apply_price_variations(base_price, i, flight_count)
        
        flight = {
          id: "mock_#{origin}_#{destination}_#{i}_#{Time.current.to_i}",
          price: price.round(2),
          currency: params[:currency] || 'USD',
          origin: {
            code: origin,
            name: get_airport_name(origin),
            city: get_airport_city(origin)
          },
          destination: {
            code: destination,
            name: get_airport_name(destination),
            city: get_airport_city(destination)
          },
          outbound: {
            departure_date: generate_departure_time(departure_date),
            arrival_date: generate_arrival_time(departure_date, origin, destination),
            carrier: random_airline,
            carrier_code: random_airline_code,
            direct: i < (flight_count * 0.6), # 60% direct flights
            stops: i < (flight_count * 0.6) ? 0 : (i % 3), # 0-2 stops
            duration: calculate_duration(origin, destination, i < (flight_count * 0.6))
          },
          inbound: return_date ? {
            departure_date: generate_departure_time(return_date),
            arrival_date: generate_arrival_time(return_date, destination, origin),
            carrier: random_airline,
            carrier_code: random_airline_code,
            direct: (i + 5) < (flight_count * 0.6),
            stops: (i + 5) < (flight_count * 0.6) ? 0 : ((i + 5) % 3),
            duration: calculate_duration(destination, origin, (i + 5) < (flight_count * 0.6))
          } : nil,
          airline: {
            code: random_airline_code,
            name: random_airline
          },
          flight_number: "#{random_airline_code}#{rand(1000..9999)}",
          cabin_class: cabin_class,
          duration: calculate_duration(origin, destination, i < (flight_count * 0.6)),
          stops: i < (flight_count * 0.6) ? 0 : (i % 3),
          booking_link: "https://example.com/book/#{i}",
          source: 'mock',
          data_quality_score: 0.85 + (rand * 0.15), # 0.85-1.0
          refundable: rand > 0.3,
          baggage_included: rand > 0.2,
          raw_data: {
            mock: true,
            generated_at: Time.current.iso8601
          }
        }
        
        flights << flight
      end
      
      # Sort by price
      flights.sort_by { |f| f[:price] }
    end

    def get_flight_details(flight_id)
      # Return mock flight details
      {
        id: flight_id,
        price: rand(200..800),
        currency: 'USD',
        route_details: {
          origin: 'JFK',
          destination: 'LAX',
          duration: '5h 30m'
        },
        booking_options: ['Standard', 'Flexible'],
        source: 'mock',
        note: 'Mock flight data for testing'
      }
    end

    def search_wedding_packages(wedding_date, destination, guest_count = 1)
      # Generate wedding-optimized mock flights
      search_params = {
        origin: 'US',
        destination: destination,
        outbound_date: (wedding_date - 2.days).strftime('%Y-%m-%d'),
        inbound_date: (wedding_date + 2.days).strftime('%Y-%m-%d'),
        adults: guest_count,
        cabin_class: 'economy',
        currency: 'USD'
      }
      
      search_flights(search_params)
    end

    def get_price_history(route, date_range)
      # Generate historical price data
      results = []
      
      date_range.each do |date|
        base_price = calculate_base_price(route[:origin], route[:destination], 'economy')
        price_variation = 0.8 + (rand * 0.4) # 80-120% of base price
        
        results << {
          date: date,
          price: (base_price * price_variation).round(2),
          currency: 'USD',
          provider: 'mock',
          booking_class: 'economy'
        }
      end
      
      results
    end

    def get_airport_suggestions(query)
      # Return mock airport suggestions
      airports = [
        { code: 'JFK', name: 'John F. Kennedy International Airport', city: 'New York', country: 'US' },
        { code: 'LAX', name: 'Los Angeles International Airport', city: 'Los Angeles', country: 'US' },
        { code: 'ORD', name: 'O\'Hare International Airport', city: 'Chicago', country: 'US' },
        { code: 'DFW', name: 'Dallas/Fort Worth International Airport', city: 'Dallas', country: 'US' },
        { code: 'ATL', name: 'Hartsfield-Jackson Atlanta International Airport', city: 'Atlanta', country: 'US' },
        { code: 'SFO', name: 'San Francisco International Airport', city: 'San Francisco', country: 'US' },
        { code: 'SEA', name: 'Seattle-Tacoma International Airport', city: 'Seattle', country: 'US' },
        { code: 'MIA', name: 'Miami International Airport', city: 'Miami', country: 'US' },
        { code: 'LAS', name: 'McCarran International Airport', city: 'Las Vegas', country: 'US' },
        { code: 'PHX', name: 'Phoenix Sky Harbor International Airport', city: 'Phoenix', country: 'US' }
      ]
      
      # Filter by query
      query_up = query.to_s.upcase
      airports.select do |airport|
        airport[:code].upcase.include?(query_up) ||
        airport[:name].upcase.include?(query_up) ||
        airport[:city].upcase.include?(query_up)
      end
    end

    def get_price_insights(route, date_range)
      # Generate price insights
      prices = date_range.map do |date|
        base_price = calculate_base_price(route[:origin], route[:destination], 'economy')
        (base_price * (0.8 + rand * 0.4)).round(2)
      end
      
      {
        route: route,
        price_range: {
          min: prices.min,
          max: prices.max,
          average: (prices.sum / prices.length).round(2)
        },
        price_trend: rand > 0.5 ? 'decreasing' : (rand > 0.5 ? 'stable' : 'increasing'),
        price_volatility: calculate_volatility(prices),
        recommendation: rand > 0.6 ? 'book_now' : (rand > 0.5 ? 'good_deal' : 'wait'),
        confidence: 0.7 + (rand * 0.3)
      }
    end

    private

    def api_key_name
      :mock
    end

    def base_url
      'https://mock-api.example.com'
    end

    def calculate_base_price(origin, destination, cabin_class)
      # Calculate realistic base price based on route distance and cabin class
      distance = calculate_route_distance(origin, destination)
      
      # Base price per mile (varies by cabin class)
      price_per_mile = case cabin_class.to_s.downcase
      when 'economy'
        0.15
      when 'premium_economy'
        0.25
      when 'business'
        0.50
      when 'first'
        0.80
      else
        0.15
      end
      
      base = distance * price_per_mile
      
      # Add route-specific adjustments
      base = apply_route_adjustments(base, origin, destination)
      
      # Ensure minimum price
      [base, 100].max.round(2)
    end

    def calculate_route_distance(origin, destination)
      # Mock distance calculation (in miles)
      # In real implementation, this would use airport coordinates
      route_distances = {
        'JFK-LAX' => 2475,
        'LAX-JFK' => 2475,
        'JFK-SFO' => 2565,
        'SFO-JFK' => 2565,
        'LAX-ORD' => 1745,
        'ORD-LAX' => 1745,
        'JFK-ORD' => 740,
        'ORD-JFK' => 740,
        'LAX-DFW' => 1235,
        'DFW-LAX' => 1235,
        'ATL-LAX' => 1944,
        'LAX-ATL' => 1944
      }
      
      route_key = "#{origin}-#{destination}"
      route_distances[route_key] || 1500 # Default distance
    end

    def apply_route_adjustments(base_price, origin, destination)
      # Apply popular route premiums
      popular_routes = {
        'JFK-LAX' => 1.2,  # 20% premium for popular routes
        'LAX-JFK' => 1.2,
        'JFK-SFO' => 1.15,
        'SFO-JFK' => 1.15,
        'NYC-LAX' => 1.2,
        'LAX-NYC' => 1.2
      }
      
      route_key = "#{origin}-#{destination}"
      multiplier = popular_routes[route_key] || 1.0
      
      base_price * multiplier
    end

    def apply_price_variations(base_price, index, total)
      # Apply realistic price variations
      # Cheaper flights are more common (early booking, budget airlines)
      position_factor = index.to_f / total
      
      # Create a distribution where:
      # - First 30% are budget prices (60-80% of base)
      # - Middle 40% are normal prices (80-120% of base)
      # - Last 30% are premium prices (120-150% of base)
      
      if position_factor < 0.3
        multiplier = 0.6 + (position_factor / 0.3) * 0.2 # 0.6 to 0.8
      elsif position_factor < 0.7
        multiplier = 0.8 + ((position_factor - 0.3) / 0.4) * 0.4 # 0.8 to 1.2
      else
        multiplier = 1.2 + ((position_factor - 0.7) / 0.3) * 0.3 # 1.2 to 1.5
      end
      
      base_price * multiplier
    end

    def generate_departure_time(date_str)
      date = Date.parse(date_str) rescue Date.today
      # Random time between 6 AM and 10 PM
      hour = rand(6..22)
      minute = [0, 15, 30, 45].sample
      Time.new(date.year, date.month, date.day, hour, minute, 0).iso8601
    end

    def generate_arrival_time(departure_date_str, origin, destination)
      departure_time_str = generate_departure_time(departure_date_str)
      departure = Time.parse(departure_time_str)
      duration_hours = calculate_duration(origin, destination, true) / 60.0
      (departure + duration_hours.hours).iso8601
    end

    def calculate_duration(origin, destination, direct)
      # Mock duration calculation
      base_hours = calculate_route_distance(origin, destination) / 550.0 # Average speed
      
      if direct
        base_hours * 60 # Convert to minutes
      else
        # Add layover time
        layover = rand(60..240) # 1-4 hour layover
        (base_hours * 60) + layover
      end
    end

    def random_airline
      airlines = [
        'American Airlines',
        'United Airlines',
        'Delta Air Lines',
        'Southwest Airlines',
        'JetBlue Airways',
        'Alaska Airlines',
        'Spirit Airlines',
        'Frontier Airlines',
        'British Airways',
        'Lufthansa',
        'Air France',
        'KLM Royal Dutch Airlines'
      ]
      airlines.sample
    end

    def random_airline_code
      codes = ['AA', 'UA', 'DL', 'WN', 'B6', 'AS', 'NK', 'F9', 'BA', 'LH', 'AF', 'KL']
      codes.sample
    end

    def get_airport_name(code)
      airport_names = {
        'JFK' => 'John F. Kennedy International Airport',
        'LAX' => 'Los Angeles International Airport',
        'ORD' => 'O\'Hare International Airport',
        'DFW' => 'Dallas/Fort Worth International Airport',
        'ATL' => 'Hartsfield-Jackson Atlanta International Airport',
        'SFO' => 'San Francisco International Airport',
        'SEA' => 'Seattle-Tacoma International Airport',
        'MIA' => 'Miami International Airport',
        'LAS' => 'McCarran International Airport',
        'PHX' => 'Phoenix Sky Harbor International Airport',
        'DEN' => 'Denver International Airport',
        'BOS' => 'Logan International Airport',
        'IAD' => 'Washington Dulles International Airport',
        'EWR' => 'Newark Liberty International Airport',
        'LGA' => 'LaGuardia Airport'
      }
      airport_names[code.upcase] || "#{code} Airport"
    end

    def get_airport_city(code)
      airport_cities = {
        'JFK' => 'New York',
        'LAX' => 'Los Angeles',
        'ORD' => 'Chicago',
        'DFW' => 'Dallas',
        'ATL' => 'Atlanta',
        'SFO' => 'San Francisco',
        'SEA' => 'Seattle',
        'MIA' => 'Miami',
        'LAS' => 'Las Vegas',
        'PHX' => 'Phoenix',
        'DEN' => 'Denver',
        'BOS' => 'Boston',
        'IAD' => 'Washington',
        'EWR' => 'Newark',
        'LGA' => 'New York'
      }
      airport_cities[code.upcase] || 'Unknown City'
    end

    def calculate_volatility(prices)
      return 0 if prices.length < 2
      
      mean = prices.sum / prices.length
      variance = prices.sum { |p| (p - mean) ** 2 } / prices.length
      Math.sqrt(variance).round(2)
    end

  end
end
