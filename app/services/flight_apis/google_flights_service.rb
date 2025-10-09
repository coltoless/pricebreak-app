module FlightApis
  class GoogleFlightsService < BaseApiService
    def initialize
      super
      @api_key = FLIGHT_APIS_CONFIG[:google_flights][:api_key]
    end

    def search_flights(params = {})
      return [] unless @api_key

      # Google Flights uses QPX Express API (deprecated but still functional)
      # For production, consider migrating to Google Travel API
      endpoint = '/trips/search'
      
      request_body = build_flight_request_body(params)
      response = make_request(endpoint, request_body, method: :post)
      
      if response && response['trips'] && response['trips']['tripOption']
        transform_flights(response['trips']['tripOption'], response['trips']['data'])
      else
        []
      end
    rescue => e
      Rails.logger.error("Google Flights search error: #{e.message}")
      []
    end

    def get_flight_details(flight_id)
      return nil unless @api_key

      # Google Flights doesn't provide individual flight details via API
      # Return basic info based on the flight ID
      {
        id: flight_id,
        source: 'google_flights',
        note: 'Detailed flight information not available via API'
      }
    rescue => e
      Rails.logger.error("Google Flights details error: #{e.message}")
      nil
    end

    def search_wedding_packages(wedding_date, destination, guest_count = 1)
      # Wedding-specific search with flexible dates
      search_params = {
        origin: 'US', # Default to US
        destination: destination,
        departure_date: (wedding_date - 2.days).strftime('%Y-%m-%d'),
        return_date: (wedding_date + 2.days).strftime('%Y-%m-%d'),
        adults: guest_count,
        cabin_class: 'economy',
        currency: 'USD',
        max_solutions: 50
      }
      
      search_flights(search_params)
    end

    def get_price_history(route, date_range)
      return [] unless @api_key

      # Google Flights can provide price insights for date ranges
      results = []
      
      # Search for prices across the date range
      date_range.each_slice(7) do |week_dates|
        params = {
          origin: route[:origin],
          destination: route[:destination],
          departure_date: week_dates.first.strftime('%Y-%m-%d'),
          return_date: week_dates.last.strftime('%Y-%m-%d'),
          adults: 1,
          currency: 'USD',
          max_solutions: 10
        }
        
        weekly_results = search_flights(params)
        results.concat(weekly_results) if weekly_results.any?
        
        # Respect rate limits
        sleep(0.2)
      end
      
      results
    rescue => e
      Rails.logger.error("Google Flights price history error: #{e.message}")
      []
    end

    def get_airport_suggestions(query)
      return [] unless @api_key

      # Google Flights doesn't provide airport suggestions via QPX API
      # Return empty array - this would need to be implemented with Google Places API
      []
    rescue => e
      Rails.logger.error("Google Flights airport suggestions error: #{e.message}")
      []
    end

    def get_price_insights(route, date_range)
      return nil unless @api_key

      # Get price insights for a route over time
      endpoint = '/trips/search'
      
      request_body = build_insights_request_body(route, date_range)
      response = make_request(endpoint, request_body, method: :post)
      
      if response && response['trips'] && response['trips']['tripOption']
        analyze_price_trends(response['trips']['tripOption'], route)
      else
        nil
      end
    rescue => e
      Rails.logger.error("Google Flights price insights error: #{e.message}")
      nil
    end

    private

    def api_key_name
      :google_flights
    end

    def base_url
      FLIGHT_APIS_CONFIG[:google_flights][:base_url]
    end

    def make_request(endpoint, body = nil, method: :get)
      # Check rate limits
      rate_limiter = FlightApis::RateLimiterService.new(:google_flights)
      unless rate_limiter.can_make_request?
        wait_time = rate_limiter.wait_time_until_available
        Rails.logger.info("Google Flights rate limit reached, waiting #{wait_time} seconds")
        sleep(wait_time)
      end

      rate_limiter.record_request

      url = "#{base_url}#{endpoint}?key=#{@api_key}"
      
      if method == :post
        response = HTTParty.post(
          url,
          body: body.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'Accept' => 'application/json'
          },
          timeout: FLIGHT_APIS_CONFIG[:google_flights][:timeout]
        )
      else
        response = HTTParty.get(
          url,
          headers: {
            'Accept' => 'application/json'
          },
          timeout: FLIGHT_APIS_CONFIG[:google_flights][:timeout]
        )
      end
      
      if response.success?
        JSON.parse(response.body)
      else
        handle_api_error(response)
        nil
      end
    rescue => e
      Rails.logger.error("Google Flights request error: #{e.message}")
      nil
    end

    def build_flight_request_body(params)
      {
        request: {
          passengers: {
            adultCount: params[:adults] || params[:passengers] || 1,
            childCount: params[:children] || 0,
            infantInSeatCount: params[:infants] || 0
          },
          slice: [
            {
              origin: params[:origin] || params[:origin_airport],
              destination: params[:destination] || params[:destination_airport],
              date: params[:departure_date] || params[:outbound_date]
            }
          ],
          solutions: params[:max_solutions] || 20,
          refundable: false
        }
      }.tap do |body|
        # Add return slice for round trips
        if params[:return_date] || params[:inbound_date]
          body[:request][:slice] << {
            origin: params[:destination] || params[:destination_airport],
            destination: params[:origin] || params[:origin_airport],
            date: params[:return_date] || params[:inbound_date]
          }
        end
        
        # Add cabin class if specified
        if params[:cabin_class]
          body[:request][:slice].each do |slice|
            slice[:preferredCabin] = normalize_cabin_class(params[:cabin_class])
          end
        end
      end
    end

    def build_insights_request_body(route, date_range)
      # Build request for price insights across multiple dates
      slices = date_range.map do |date|
        {
          origin: route[:origin],
          destination: route[:destination],
          date: date.strftime('%Y-%m-%d')
        }
      end

      {
        request: {
          passengers: { adultCount: 1 },
          slice: slices,
          solutions: 5,
          refundable: false
        }
      }
    end

    def normalize_cabin_class(cabin_class)
      case cabin_class.to_s.downcase
      when 'economy', 'coach'
        'COACH'
      when 'premium_economy', 'premium'
        'COACH' # QPX doesn't support premium economy
      when 'business'
        'BUSINESS'
      when 'first'
        'FIRST'
      else
        'COACH'
      end
    end

    def transform_flights(flights_data, trip_data)
      return [] unless flights_data.is_a?(Array)

      flights_data.map do |flight|
        # Extract segment information
        outbound_segments = flight['slice'].first['segment']
        inbound_segments = flight['slice'].length > 1 ? flight['slice'].last['segment'] : nil
        
        {
          id: flight['id'],
          price: flight['pricing'].first['saleTotal'].gsub(/[^\d.]/, '').to_f,
          currency: flight['pricing'].first['saleTotal'].gsub(/[\d.]/, ''),
          origin: extract_airport_info(outbound_segments.first['leg'].first['origin'], trip_data),
          destination: extract_airport_info(outbound_segments.last['leg'].last['destination'], trip_data),
          outbound: {
            departure_date: outbound_segments.first['leg'].first['departureTime'],
            carrier: extract_carrier_info(outbound_segments.first['flight']['carrier'], trip_data),
            direct: outbound_segments.length == 1
          },
          inbound: inbound_segments ? {
            departure_date: inbound_segments.first['leg'].first['departureTime'],
            carrier: extract_carrier_info(inbound_segments.first['flight']['carrier'], trip_data),
            direct: inbound_segments.length == 1
          } : nil,
          airline: extract_carrier_info(outbound_segments.first['flight']['carrier'], trip_data),
          flight_number: outbound_segments.first['flight']['number'],
          cabin_class: 'economy', # QPX doesn't provide cabin class details
          duration: calculate_duration(outbound_segments),
          stops: outbound_segments.length - 1,
          booking_link: generate_booking_link(flight['id']),
          source: 'google_flights',
          raw_data: flight
        }
      end
    end

    def extract_airport_info(airport_code, trip_data)
      airport_info = trip_data['airport'].find { |a| a['code'] == airport_code }
      
      {
        code: airport_code,
        name: airport_info&.dig('name'),
        city: airport_info&.dig('city'),
        country: airport_info&.dig('country')
      }
    end

    def extract_carrier_info(carrier_code, trip_data)
      carrier_info = trip_data['carrier'].find { |c| c['code'] == carrier_code }
      
      {
        code: carrier_code,
        name: carrier_info&.dig('name') || carrier_code
      }
    end

    def calculate_duration(segments)
      total_minutes = 0
      
      segments.each do |segment|
        segment['leg'].each do |leg|
          departure = Time.parse(leg['departureTime'])
          arrival = Time.parse(leg['arrivalTime'])
          total_minutes += ((arrival - departure) / 60).to_i
        end
      end
      
      total_minutes
    end

    def analyze_price_trends(flights_data, route)
      prices = flights_data.map { |f| f['pricing'].first['saleTotal'].gsub(/[^\d.]/, '').to_f }
      
      return nil if prices.empty?
      
      {
        route: route,
        price_range: {
          min: prices.min,
          max: prices.max,
          average: prices.sum / prices.length
        },
        price_trend: calculate_price_trend(prices),
        price_volatility: calculate_price_volatility(prices),
        recommendation: generate_price_recommendation(prices, route)
      }
    end

    def calculate_price_trend(prices)
      return 'stable' if prices.length < 2
      
      # Simple linear trend calculation
      n = prices.length
      sum_x = (0...n).sum
      sum_y = prices.sum
      sum_xy = (0...n).zip(prices).sum { |x, y| x * y }
      sum_x2 = (0...n).sum { |x| x * x }
      
      slope = (n * sum_xy - sum_x * sum_y) / (n * sum_x2 - sum_x * sum_x)
      
      if slope > 5
        'increasing'
      elsif slope < -5
        'decreasing'
      else
        'stable'
      end
    end

    def calculate_price_volatility(prices)
      return 0 if prices.length < 2
      
      mean = prices.sum / prices.length
      variance = prices.sum { |p| (p - mean) ** 2 } / prices.length
      Math.sqrt(variance)
    end

    def generate_price_recommendation(prices, route)
      return 'wait' if prices.length < 3
      
      current_price = prices.last
      average_price = prices.sum / prices.length
      min_price = prices.min
      
      if current_price <= min_price * 1.1
        'book_now'
      elsif current_price <= average_price * 0.9
        'good_deal'
      elsif current_price >= average_price * 1.2
        'wait'
      else
        'consider'
      end
    end

    def generate_booking_link(flight_id)
      # Google Flights doesn't provide direct booking links via API
      "https://www.google.com/travel/flights"
    end

    def handle_api_error(response)
      case response.code
      when 400
        Rails.logger.error("Google Flights bad request: #{response.body}")
      when 403
        Rails.logger.error("Google Flights API key invalid or quota exceeded")
      when 429
        Rails.logger.warn("Google Flights rate limit exceeded")
      when 500..599
        Rails.logger.error("Google Flights server error: #{response.code} - #{response.body}")
      end
    end
  end
end





