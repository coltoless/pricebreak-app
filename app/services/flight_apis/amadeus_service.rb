module FlightApis
  class AmadeusService < BaseApiService
    attr_reader :access_token, :token_expires_at

    def initialize
      super
      @access_token = nil
      @token_expires_at = nil
      authenticate
    end

    def search_flights(params = {})
      return [] unless authenticate

      endpoint = '/v2/shopping/flight-offers'
      response = make_request(endpoint, build_flight_params(params))
      
      if response && response['data']
        transform_flights(response['data'])
      else
        []
      end
    rescue => e
      Rails.logger.error("Amadeus search error: #{e.message}")
      []
    end

    def get_flight_details(flight_id)
      return nil unless authenticate

      endpoint = "/v1/shopping/flight-offers/#{flight_id}"
      response = make_request(endpoint)
      
      if response
        transform_flight_details(response)
      else
        nil
      end
    rescue => e
      Rails.logger.error("Amadeus flight details error: #{e.message}")
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
        cabin_class: 'ECONOMY',
        currency: 'USD',
        max: 50 # Get more options for wedding planning
      }
      
      search_flights(search_params)
    end

    def get_price_history(route, date_range)
      return [] unless authenticate

      # Amadeus doesn't provide direct price history, but we can get current prices
      # for a range of dates to build historical data
      results = []
      
      date_range.each do |date|
        params = {
          origin: route[:origin],
          destination: route[:destination],
          departure_date: date.strftime('%Y-%m-%d'),
          adults: 1,
          currency: 'USD'
        }
        
        daily_results = search_flights(params)
        results.concat(daily_results) if daily_results.any?
        
        # Respect rate limits
        sleep(0.1)
      end
      
      results
    rescue => e
      Rails.logger.error("Amadeus price history error: #{e.message}")
      []
    end

    def get_airport_suggestions(query)
      return [] unless authenticate

      endpoint = '/v1/reference-data/locations'
      params = {
        subType: 'AIRPORT',
        keyword: query,
        'page[limit]': 10
      }
      
      response = make_request(endpoint, params)
      
      if response && response['data']
        transform_airport_suggestions(response['data'])
      else
        []
      end
    rescue => e
      Rails.logger.error("Amadeus airport suggestions error: #{e.message}")
      []
    end

    private

    def api_key_name
      :amadeus
    end

    def base_url
      FLIGHT_APIS_CONFIG[:amadeus][:base_url]
    end

    def authenticate
      return true if @access_token && @token_expires_at && @token_expires_at > Time.current

      begin
        endpoint = '/v1/security/oauth2/token'
        response = make_auth_request(endpoint, build_auth_params)
        
        if response && response['access_token']
          @access_token = response['access_token']
          @token_expires_at = Time.current + response['expires_in'].seconds
          true
        else
          false
        end
      rescue => e
        Rails.logger.error("Amadeus authentication error: #{e.message}")
        false
      end
    end

    def build_auth_params
      {
        grant_type: 'client_credentials',
        client_id: FLIGHT_APIS_CONFIG[:amadeus][:api_key],
        client_secret: FLIGHT_APIS_CONFIG[:amadeus][:api_secret]
      }
    end

    def make_auth_request(endpoint, params)
      response = HTTParty.post(
        "#{base_url}#{endpoint}",
        body: params,
        headers: {
          'Content-Type' => 'application/x-www-form-urlencoded'
        },
        timeout: FLIGHT_APIS_CONFIG[:amadeus][:timeout]
      )
      
      if response.success?
        JSON.parse(response.body)
      else
        Rails.logger.error("Amadeus auth request failed: #{response.code} - #{response.body}")
        nil
      end
    end

    def make_request(endpoint, params = {})
      return nil unless @access_token

      # Check rate limits
      rate_limiter = FlightApis::RateLimiterService.new(:amadeus)
      unless rate_limiter.can_make_request?
        wait_time = rate_limiter.wait_time_until_available
        Rails.logger.info("Amadeus rate limit reached, waiting #{wait_time} seconds")
        sleep(wait_time)
      end

      rate_limiter.record_request

      url = "#{base_url}#{endpoint}"
      url += "?#{params.to_query}" if params.any?

      response = HTTParty.get(
        url,
        headers: {
          'Authorization' => "Bearer #{@access_token}",
          'Accept' => 'application/json'
        },
        timeout: FLIGHT_APIS_CONFIG[:amadeus][:timeout]
      )
      
      if response.success?
        JSON.parse(response.body)
      else
        handle_api_error(response)
        nil
      end
    rescue => e
      Rails.logger.error("Amadeus request error: #{e.message}")
      nil
    end

    def build_flight_params(params)
      {
        originLocationCode: params[:origin] || params[:origin_airport],
        destinationLocationCode: params[:destination] || params[:destination_airport],
        departureDate: params[:departure_date] || params[:outbound_date],
        returnDate: params[:return_date] || params[:inbound_date],
        adults: params[:adults] || params[:passengers] || 1,
        children: params[:children] || 0,
        infants: params[:infants] || 0,
        travelClass: normalize_cabin_class(params[:cabin_class]),
        currencyCode: params[:currency] || 'USD',
        max: params[:max] || 20,
        nonStop: params[:non_stop] || false
      }.compact
    end

    def normalize_cabin_class(cabin_class)
      case cabin_class.to_s.downcase
      when 'economy', 'coach'
        'ECONOMY'
      when 'premium_economy', 'premium'
        'PREMIUM_ECONOMY'
      when 'business'
        'BUSINESS'
      when 'first'
        'FIRST'
      else
        'ECONOMY'
      end
    end

    def transform_flights(flights_data)
      return [] unless flights_data.is_a?(Array)

      flights_data.map do |flight|
        {
          id: flight['id'],
          price: flight['price']['total'].to_f,
          currency: flight['price']['currency'],
          origin: {
            code: flight['itineraries'].first['segments'].first['departure']['iataCode'],
            name: flight['itineraries'].first['segments'].first['departure']['terminal'],
            city: flight['itineraries'].first['segments'].first['departure']['iataCode']
          },
          destination: {
            code: flight['itineraries'].first['segments'].last['arrival']['iataCode'],
            name: flight['itineraries'].first['segments'].last['arrival']['terminal'],
            city: flight['itineraries'].first['segments'].last['arrival']['iataCode']
          },
          outbound: {
            departure_date: flight['itineraries'].first['segments'].first['departure']['at'],
            carrier: flight['itineraries'].first['segments'].first['carrierCode'],
            direct: flight['itineraries'].first['segments'].length == 1
          },
          inbound: flight['itineraries'].length > 1 ? {
            departure_date: flight['itineraries'].last['segments'].first['departure']['at'],
            carrier: flight['itineraries'].last['segments'].first['carrierCode'],
            direct: flight['itineraries'].last['segments'].length == 1
          } : nil,
          airline: {
            code: flight['itineraries'].first['segments'].first['carrierCode'],
            name: flight['itineraries'].first['segments'].first['carrierCode']
          },
          flight_number: flight['itineraries'].first['segments'].first['number'],
          cabin_class: flight['travelerPricings'].first['fareDetailsBySegment'].first['cabin'],
          duration: flight['itineraries'].first['duration'],
          stops: flight['itineraries'].first['segments'].length - 1,
          booking_link: generate_booking_link(flight['id']),
          source: 'amadeus',
          raw_data: flight
        }
      end
    end

    def transform_flight_details(flight_data)
      {
        id: flight_data['id'],
        price: flight_data['price']['total'].to_f,
        currency: flight_data['price']['currency'],
        route_details: flight_data['itineraries'],
        booking_options: flight_data['pricingOptions'],
        fare_details: flight_data['fareDetailsBySegment'],
        traveler_pricing: flight_data['travelerPricings'],
        source: 'amadeus'
      }
    end

    def transform_airport_suggestions(airports_data)
      airports_data.map do |airport|
        {
          code: airport['iataCode'],
          name: airport['name'],
          city: airport['address']['cityName'],
          country: airport['address']['countryCode'],
          latitude: airport['geoCode']['latitude'],
          longitude: airport['geoCode']['longitude']
        }
      end
    end

    def generate_booking_link(flight_id)
      # Amadeus doesn't provide direct booking links, but we can link to their search
      "https://www.amadeus.com/flights/#{flight_id}"
    end

    def handle_api_error(response)
      case response.code
      when 401
        # Token expired, re-authenticate
        @access_token = nil
        @token_expires_at = nil
        authenticate
      when 429
        # Rate limited
        Rails.logger.warn("Amadeus rate limit exceeded")
      when 400..499
        Rails.logger.error("Amadeus client error: #{response.code} - #{response.body}")
      when 500..599
        Rails.logger.error("Amadeus server error: #{response.code} - #{response.body}")
      end
    end
  end
end





