module FlightApis
  class DataValidationService
    include ActiveModel::Validations

    attr_reader :validation_errors, :filtered_count, :validated_count

    def initialize
      @validation_errors = []
      @filtered_count = 0
      @validated_count = 0
    end

    def validate_flight_data(flight_data, provider = nil)
      return { success: false, errors: ['No data provided'] } if flight_data.blank?

      @validation_errors = []
      @filtered_count = 0
      @validated_count = 0

      begin
        if flight_data.is_a?(Array)
          validated_data = flight_data.map { |flight| validate_single_flight(flight, provider) }.compact
        else
          validated_data = [validate_single_flight(flight_data, provider)].compact
        end

        {
          success: true,
          data: validated_data,
          stats: {
            validated: @validated_count,
            filtered: @filtered_count,
            errors: @validation_errors.count
          }
        }
      rescue => e
        @validation_errors << "Validation error: #{e.message}"
        { success: false, errors: @validation_errors, data: [] }
      end
    end

    def validate_single_flight(flight, provider = nil)
      return nil unless flight.is_a?(Hash)

      validation_results = []
      
      # Route validation
      route_validation = validate_route(flight)
      validation_results.concat(route_validation)
      
      # Date validation
      date_validation = validate_dates(flight)
      validation_results.concat(date_validation)
      
      # Price validation
      price_validation = validate_price(flight)
      validation_results.concat(price_validation)
      
      # Airline and flight validation
      airline_validation = validate_airline_and_flight(flight)
      validation_results.concat(airline_validation)
      
      # Provider-specific validation
      provider_validation = validate_provider_specific(flight, provider)
      validation_results.concat(provider_validation)

      # Calculate overall validation score
      validation_score = calculate_validation_score(validation_results)
      
      if validation_score >= FLIGHT_API_GLOBAL_CONFIG[:data_quality_threshold]
        @validated_count += 1
        
        # Add validation metadata to flight
        flight[:validation_score] = validation_score
        flight[:validation_errors] = validation_results
        flight[:data_quality_score] = validation_score
        flight[:is_valid] = true
        
        flight
      else
        @filtered_count += 1
        @validation_errors.concat(validation_results)
        nil
      end
    end

    def validate_route(flight)
      errors = []
      
      origin = flight[:origin]
      destination = flight[:destination]
      
      # Check if origin and destination are present
      unless origin && destination
        errors << "Missing origin or destination"
        return errors
      end
      
      origin_code = origin.is_a?(Hash) ? origin[:code] : origin
      destination_code = destination.is_a?(Hash) ? destination[:code] : destination
      
      # Check for invalid airport codes
      unless valid_airport_code?(origin_code)
        errors << "Invalid origin airport code: #{origin_code}"
      end
      
      unless valid_airport_code?(destination_code)
        errors << "Invalid destination airport code: #{destination_code}"
      end
      
      # Check for impossible route combinations
      if origin_code && destination_code
        impossible_route = check_impossible_route(origin_code, destination_code)
        if impossible_route
          errors << "Impossible route: #{origin_code}-#{destination_code} (#{impossible_route})"
        end
        
        # Check for seasonal routes
        seasonal_validation = check_seasonal_route(origin_code, destination_code)
        if seasonal_validation[:is_seasonal] && !seasonal_validation[:is_available]
          errors << "Seasonal route not available: #{origin_code}-#{destination_code} (#{seasonal_validation[:reason]})"
        end
        
        # Check for reasonable distance
        distance_validation = validate_route_distance(origin_code, destination_code)
        unless distance_validation[:is_valid]
          errors << "Unreasonable route distance: #{distance_validation[:distance]}km (#{distance_validation[:reason]})"
        end
      end
      
      errors
    end

    def validate_dates(flight)
      errors = []
      
      departure_date = flight[:departure_date] || flight[:outbound]&.dig(:departure_date)
      return_date = flight[:return_date] || flight[:inbound]&.dig(:departure_date)
      
      # Check departure date
      if departure_date
        departure_validation = validate_single_date(departure_date, 'departure')
        errors.concat(departure_validation)
      else
        errors << "Missing departure date"
      end
      
      # Check return date if round trip
      if return_date
        return_validation = validate_single_date(return_date, 'return')
        errors.concat(return_validation)
        
        # Check return date is after departure date
        if departure_date && return_date
          begin
            dep_date = departure_date.is_a?(Date) ? departure_date : Date.parse(departure_date.to_s)
            ret_date = return_date.is_a?(Date) ? return_date : Date.parse(return_date.to_s)
            
            if ret_date <= dep_date
              errors << "Return date must be after departure date"
            end
            
            # Check for reasonable trip duration
            trip_duration = (ret_date - dep_date).to_i
            if trip_duration > 365
              errors << "Trip duration exceeds 1 year"
            elsif trip_duration < 0
              errors << "Invalid trip duration"
            end
          rescue Date::Error
            errors << "Invalid date format"
          end
        end
      end
      
      errors
    end

    def validate_price(flight)
      errors = []
      
      price = flight[:price]
      currency = flight[:currency]
      
      unless price
        errors << "Missing price information"
        return errors
      end
      
      # Convert price to USD for validation
      price_usd = convert_price_to_usd(price, currency)
      
      # Check price range
      if price_usd < PRICE_VALIDATION_RULES[:min_price_usd]
        errors << "Price too low: $#{price_usd} (minimum: $#{PRICE_VALIDATION_RULES[:min_price_usd]})"
      elsif price_usd > PRICE_VALIDATION_RULES[:max_price_usd]
        errors << "Price too high: $#{price_usd} (maximum: $#{PRICE_VALIDATION_RULES[:max_price_usd]})"
      end
      
      # Check for suspicious pricing patterns
      suspicious_patterns = detect_suspicious_pricing(price_usd)
      if suspicious_patterns.any?
        errors.concat(suspicious_patterns)
      end
      
      # Check for price anomalies compared to route average
      price_anomaly = detect_price_anomaly(flight, price_usd)
      if price_anomaly
        errors << price_anomaly
      end
      
      errors
    end

    def validate_airline_and_flight(flight)
      errors = []
      
      airline = flight[:airline]
      flight_number = flight[:flight_number]
      
      # Validate airline information
      if airline
        if airline.is_a?(Hash)
          airline_code = airline[:code]
          airline_name = airline[:name]
          
          unless airline_code || airline_name
            errors << "Airline missing both code and name"
          end
          
          if airline_code && !valid_airline_code?(airline_code)
            errors << "Invalid airline code: #{airline_code}"
          end
        else
          # String airline
          unless valid_airline_code?(airline.to_s)
            errors << "Invalid airline: #{airline}"
          end
        end
      end
      
      # Validate flight number
      if flight_number
        unless valid_flight_number?(flight_number)
          errors << "Invalid flight number: #{flight_number}"
        end
      end
      
      # Validate cabin class
      cabin_class = flight[:cabin_class]
      if cabin_class && !valid_cabin_class?(cabin_class)
        errors << "Invalid cabin class: #{cabin_class}"
      end
      
      errors
    end

    def validate_provider_specific(flight, provider)
      errors = []
      
      case provider&.to_s
      when 'skyscanner'
        errors.concat(validate_skyscanner_specific(flight))
      when 'amadeus'
        errors.concat(validate_amadeus_specific(flight))
      when 'google_flights'
        errors.concat(validate_google_flights_specific(flight))
      end
      
      errors
    end

    def validate_skyscanner_specific(flight)
      errors = []
      
      # Skyscanner-specific validations
      if flight[:outbound] && flight[:outbound][:carrier]
        carrier = flight[:outbound][:carrier]
        unless carrier.is_a?(String) || (carrier.is_a?(Hash) && (carrier[:code] || carrier[:name]))
          errors << "Invalid Skyscanner carrier format"
        end
      end
      
      errors
    end

    def validate_amadeus_specific(flight)
      errors = []
      
      # Amadeus-specific validations
      if flight[:itineraries]
        unless flight[:itineraries].is_a?(Array) && flight[:itineraries].any?
          errors << "Amadeus flight missing itinerary information"
        end
      end
      
      errors
    end

    def validate_google_flights_specific(flight)
      errors = []
      
      # Google Flights-specific validations
      if flight[:slice]
        unless flight[:slice].is_a?(Array) && flight[:slice].any?
          errors << "Google Flights missing slice information"
        end
      end
      
      errors
    end

    def calculate_validation_score(validation_results)
      return 1.0 if validation_results.empty?
      
      # Start with perfect score and deduct for each error
      base_score = 1.0
      error_penalty = 0.1
      
      validation_results.each do |error|
        # Different penalties for different error types
        case error
        when /^Missing/
          base_score -= error_penalty * 0.5
        when /^Invalid/
          base_score -= error_penalty * 0.8
        when /^Impossible/
          base_score -= error_penalty * 1.0
        when /^Price too/
          base_score -= error_penalty * 0.6
        else
          base_score -= error_penalty * 0.3
        end
      end
      
      [base_score, 0.0].max
    end

    private

    def valid_airport_code?(code)
      return false unless code
      
      # Basic airport code validation (3 letters for IATA)
      code.to_s.match?(/^[A-Z]{3}$/)
    end

    def valid_airline_code?(code)
      return false unless code
      
      # Basic airline code validation (2-3 characters)
      code.to_s.match?(/^[A-Z0-9]{2,3}$/)
    end

    def valid_flight_number?(number)
      return false unless number
      
      # Basic flight number validation
      number.to_s.match?(/^[0-9]{1,4}[A-Z]?$/)
    end

    def valid_cabin_class?(cabin_class)
      return false unless cabin_class
      
      valid_classes = ['economy', 'premium_economy', 'business', 'first']
      valid_classes.include?(cabin_class.to_s.downcase)
    end

    def check_impossible_route(origin, destination)
      ROUTE_VALIDATION_RULES[:invalid_combinations].each do |invalid_route|
        if (invalid_route[:origin] == origin && invalid_route[:destination] == destination) ||
           (invalid_route[:origin] == destination && invalid_route[:destination] == origin)
          return invalid_route[:reason]
        end
      end
      
      nil
    end

    def check_seasonal_route(origin, destination)
      route_key = "#{origin}-#{destination}"
      seasonal_info = ROUTE_VALIDATION_RULES[:seasonal_routes][route_key]
      
      if seasonal_info
        current_month = Time.current.month
        is_available = seasonal_info[:months].include?(current_month)
        
        {
          is_seasonal: true,
          is_available: is_available,
          reason: seasonal_info[:reason]
        }
      else
        { is_seasonal: false, is_available: true }
      end
    end

    def validate_route_distance(origin, destination)
      # This would typically use a real distance calculation service
      # For now, we'll use a simplified approach
      distance = calculate_approximate_distance(origin, destination)
      
      if distance < ROUTE_VALIDATION_RULES[:min_distance_km]
        {
          is_valid: false,
          distance: distance,
          reason: "Distance below minimum threshold"
        }
      elsif distance > ROUTE_VALIDATION_RULES[:max_distance_km]
        {
          is_valid: false,
          distance: distance,
          reason: "Distance above maximum threshold"
        }
      else
        {
          is_valid: true,
          distance: distance
        }
      end
    end

    def calculate_approximate_distance(origin, destination)
      # Simplified distance calculation - in production, use a proper geocoding service
      # This is just a placeholder that returns a reasonable value
      1500 # Default to 1500km
    end

    def validate_single_date(date, date_type)
      errors = []
      
      begin
        parsed_date = date.is_a?(Date) ? date : Date.parse(date.to_s)
        current_date = Date.current
        
        # Check if date is in the past
        if parsed_date < current_date
          errors << "#{date_type.capitalize} date cannot be in the past"
        end
        
        # Check if date is too far in the future
        if parsed_date > current_date + 2.years
          errors << "#{date_type.capitalize} date too far in the future"
        end
        
      rescue Date::Error
        errors << "Invalid #{date_type} date format"
      end
      
      errors
    end

    def convert_price_to_usd(price, currency)
      return price.to_f if currency.to_s.upcase == 'USD'
      
      currency_sym = currency.to_s.upcase.to_sym
      if CURRENCY_CONVERSION[currency_sym]
        price.to_f * CURRENCY_CONVERSION[currency_sym]
      else
        # If we can't convert, assume it's close to USD for validation purposes
        price.to_f
      end
    end

    def detect_suspicious_pricing(price_usd)
      errors = []
      
      PRICE_VALIDATION_RULES[:suspicious_patterns].each do |pattern|
        case pattern
        when 'price_ends_in_999'
          if price_usd.to_s.end_with?('999')
            errors << "Suspicious pricing pattern: price ends in 999"
          end
        when 'price_divisible_by_100'
          if (price_usd % 100).zero?
            errors << "Suspicious pricing pattern: price is divisible by 100"
          end
        end
      end
      
      errors
    end

    def detect_price_anomaly(flight, price_usd)
      # This would typically compare against historical price data
      # For now, we'll use basic heuristics
      
      origin = flight[:origin]
      destination = flight[:destination]
      
      if origin && destination
        # Simple price validation based on route type
        route_type = determine_route_type(origin, destination)
        expected_price_range = get_expected_price_range(route_type)
        
        if expected_price_range
          if price_usd < expected_price_range[:min]
            return "Price suspiciously low for #{route_type} route"
          elsif price_usd > expected_price_range[:max]
            return "Price suspiciously high for #{route_type} route"
          end
        end
      end
      
      nil
    end

    def determine_route_type(origin, destination)
      # Determine if domestic, international, or long-haul
      # This is a simplified implementation
      'domestic' # Placeholder
    end

    def get_expected_price_range(route_type)
      # Expected price ranges for different route types
      case route_type
      when 'domestic'
        { min: 50, max: 800 }
      when 'international'
        { min: 200, max: 2000 }
      when 'long_haul'
        { min: 500, max: 5000 }
      else
        nil
      end
    end
  end
end





