module FlightApis
  class DataNormalizerService
    include ActiveModel::Validations

    attr_reader :errors, :normalized_count, :converted_count

    def initialize
      @errors = []
      @normalized_count = 0
      @converted_count = 0
    end

    def normalize_flight_data(raw_data, provider)
      return [] if raw_data.blank?

      @errors = []
      @normalized_count = 0
      @converted_count = 0

      begin
        normalized_data = raw_data.map do |flight|
          normalize_single_flight(flight, provider)
        end.compact

        {
          success: true,
          data: normalized_data,
          stats: {
            normalized: @normalized_count,
            converted: @converted_count,
            errors: @errors.count
          }
        }
      rescue => e
        @errors << "Normalization error: #{e.message}"
        { success: false, errors: @errors, data: [] }
      end
    end

    def normalize_single_flight(flight, provider)
      return nil unless flight.is_a?(Hash)

      begin
        normalized = {
          # Basic flight information
          id: generate_flight_id(flight, provider),
          provider: provider.to_s,
          provider_flight_id: flight[:id] || flight[:quote_id] || flight[:flight_id],
          
          # Route information
          origin: normalize_airport(flight[:origin]),
          destination: normalize_airport(flight[:destination]),
          
          # Pricing information
          price: normalize_price(flight[:price], flight[:currency]),
          currency: 'USD', # Always convert to USD
          
          # Flight details
          departure_date: normalize_date(flight[:departure_date] || flight[:outbound]&.dig(:departure_date)),
          return_date: normalize_date(flight[:return_date] || flight[:inbound]&.dig(:departure_date)),
          
          # Airline and flight details
          airline: normalize_airline(flight[:airline] || flight[:carrier]),
          flight_number: flight[:flight_number],
          cabin_class: normalize_cabin_class(flight[:cabin_class]),
          
          # Route details
          stops: normalize_stops(flight[:stops], flight[:direct]),
          duration: normalize_duration(flight[:duration]),
          
          # Additional metadata
          source: provider.to_s,
          data_timestamp: Time.current,
          raw_data: flight
        }

        # Handle round-trip vs one-way
        if flight[:inbound] || flight[:return_date]
          normalized[:trip_type] = 'round_trip'
          normalized[:return_airline] = normalize_airline(flight[:inbound]&.dig(:carrier) || flight[:return_airline])
          normalized[:return_flight_number] = flight[:inbound]&.dig(:flight_number) || flight[:return_flight_number]
        else
          normalized[:trip_type] = 'one_way'
        end

        @normalized_count += 1
        normalized

      rescue => e
        @errors << "Flight normalization error: #{e.message}"
        nil
      end
    end

    def normalize_airport(airport_data)
      return nil if airport_data.blank?

      if airport_data.is_a?(Hash)
        {
          code: normalize_airport_code(airport_data[:code] || airport_data[:iata_code]),
          name: airport_data[:name],
          city: airport_data[:city] || airport_data[:city_name],
          country: airport_data[:country] || airport_data[:country_code]
        }
      else
        # Handle string airport codes
        {
          code: normalize_airport_code(airport_data.to_s),
          name: nil,
          city: nil,
          country: nil
        }
      end
    end

    def normalize_airport_code(code)
      return nil if code.blank?
      
      code = code.to_s.upcase.strip
      
      # Handle city codes (NYC, LON, PAR, etc.)
      if AIRPORT_CODE_MAPPINGS[code]
        # Return the first airport in the city group
        AIRPORT_CODE_MAPPINGS[code].first
      else
        code
      end
    end

    def normalize_price(price, currency)
      return nil if price.blank?

      price = price.to_f
      currency = currency.to_s.upcase.to_sym

      # Convert to USD if needed
      if currency != :USD && CURRENCY_CONVERSION[currency]
        @converted_count += 1
        price * CURRENCY_CONVERSION[currency]
      else
        price
      end
    end

    def normalize_date(date_string)
      return nil if date_string.blank?

      begin
        if date_string.is_a?(String)
          # Handle various date formats
          if date_string.match?(/^\d{4}-\d{2}-\d{2}/)
            Date.parse(date_string)
          elsif date_string.match?(/^\d{2}\/\d{2}\/\d{4}/)
            Date.strptime(date_string, '%m/%d/%Y')
          else
            Date.parse(date_string)
          end
        elsif date_string.is_a?(Date)
          date_string
        elsif date_string.is_a?(Time) || date_string.is_a?(DateTime)
          date_string.to_date
        end
      rescue => e
        @errors << "Date parsing error: #{e.message}"
        nil
      end
    end

    def normalize_airline(airline_data)
      return nil if airline_data.blank?

      if airline_data.is_a?(Hash)
        {
          code: airline_data[:code] || airline_data[:iata_code],
          name: airline_data[:name] || airline_data[:carrier_name]
        }
      else
        # Handle string airline codes or names
        airline_code = airline_data.to_s.upcase
        {
          code: airline_code,
          name: AIRLINE_CODE_MAPPING[airline_code] || airline_data.to_s
        }
      end
    end

    def normalize_cabin_class(cabin_class)
      return 'economy' if cabin_class.blank?

      cabin_class = cabin_class.to_s.downcase.strip
      
      CABIN_CLASS_MAPPING.each do |normalized_class, variations|
        return normalized_class if variations.include?(cabin_class)
      end
      
      # Default fallback
      'economy'
    end

    def normalize_stops(stops, direct)
      return 0 if direct == true
      return stops.to_i if stops.present?
      
      # Infer from other data if available
      nil
    end

    def normalize_duration(duration)
      return nil if duration.blank?

      if duration.is_a?(String)
        # Parse duration strings like "2h 30m", "2:30", etc.
        parse_duration_string(duration)
      elsif duration.is_a?(Numeric)
        duration
      else
        duration
      end
    end

    def generate_flight_id(flight, provider)
      # Generate a unique ID based on flight characteristics
      origin_code = flight[:origin]&.dig(:code) || flight[:origin]
      dest_code = flight[:destination]&.dig(:code) || flight[:destination]
      
      components = [
        provider.to_s,
        origin_code,
        dest_code,
        flight[:departure_date] || flight[:outbound]&.dig(:departure_date),
        flight[:airline]&.dig(:code) || flight[:carrier],
        flight[:flight_number],
        flight[:price]
      ].compact.map(&:to_s).join('_')
      
      Digest::MD5.hexdigest(components)[0..15]
    end

    def validate_normalized_data(normalized_data)
      validation_errors = []
      
      normalized_data.each_with_index do |flight, index|
        # Check required fields
        required_fields = [:origin, :destination, :price, :departure_date]
        required_fields.each do |field|
          if flight[field].blank?
            validation_errors << "Flight #{index}: Missing required field '#{field}'"
          end
        end
        
        # Validate price range
        if flight[:price] && (flight[:price] < PRICE_VALIDATION_RULES[:min_price_usd] || 
                              flight[:price] > PRICE_VALIDATION_RULES[:max_price_usd])
          validation_errors << "Flight #{index}: Price #{flight[:price]} is outside valid range"
        end
        
        # Validate route
        if flight[:origin] && flight[:destination]
          route_validation = validate_route(flight[:origin][:code], flight[:destination][:code])
          validation_errors.concat(route_validation) if route_validation.any?
        end
      end
      
      validation_errors
    end

    private

    def parse_duration_string(duration_str)
      # Parse various duration formats
      if duration_str.match?(/(\d+)h\s*(\d+)?m?/)
        hours = $1.to_i
        minutes = $2.to_i
        hours * 60 + minutes
      elsif duration_str.match?(/(\d+):(\d+)/)
        hours = $1.to_i
        minutes = $2.to_i
        hours * 60 + minutes
      else
        # Try to extract any numbers
        duration_str.scan(/\d+/).map(&:to_i).sum
      end
    end

    def validate_route(origin_code, destination_code)
      errors = []
      
      # Check for invalid combinations
      ROUTE_VALIDATION_RULES[:invalid_combinations].each do |invalid_route|
        if (invalid_route[:origin] == origin_code && invalid_route[:destination] == destination_code) ||
           (invalid_route[:origin] == destination_code && invalid_route[:destination] == origin_code)
          errors << "Invalid route combination: #{origin_code}-#{destination_code} (#{invalid_route[:reason]})"
        end
      end
      
      # Check seasonal routes
      route_key = "#{origin_code}-#{destination_code}"
      if ROUTE_VALIDATION_RULES[:seasonal_routes][route_key]
        seasonal_info = ROUTE_VALIDATION_RULES[:seasonal_routes][route_key]
        current_month = Time.current.month
        
        unless seasonal_info[:months].include?(current_month)
          errors << "Seasonal route #{route_key} is not available in month #{current_month} (#{seasonal_info[:reason]})"
        end
      end
      
      errors
    end
  end
end
