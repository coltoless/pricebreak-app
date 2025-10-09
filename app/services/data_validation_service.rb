class DataValidationService
  include ActiveModel::Validations

  attr_reader :validation_results, :errors, :warnings

  def initialize
    @validation_results = {}
    @errors = []
    @warnings = []
  end

  def validate_flight_data(flight_data, provider)
    @validation_results = {}
    @errors = []
    @warnings = []
    
    begin
      # Validate individual flight records
      flight_data.each_with_index do |flight, index|
        validation_result = validate_single_flight(flight, provider)
        @validation_results[index] = validation_result
        
        if validation_result[:is_valid] == false
          @errors << "Flight #{index}: #{validation_result[:errors].join(', ')}"
        elsif validation_result[:warnings].any?
          @warnings << "Flight #{index}: #{validation_result[:warnings].join(', ')}"
        end
      end
      
      # Validate data consistency across the dataset
      validate_dataset_consistency(flight_data, provider)
      
      {
        success: @errors.empty?,
        total_flights: flight_data.count,
        valid_flights: @validation_results.values.count { |r| r[:is_valid] },
        invalid_flights: @validation_results.values.count { |r| r[:is_valid] == false },
        warnings: @warnings.count,
        errors: @errors,
        warnings: @warnings,
        detailed_results: @validation_results
      }
    rescue => e
      @errors << "Validation error: #{e.message}"
      { success: false, errors: @errors }
    end
  end

  def validate_route_validity(origin, destination, trip_type)
    validation_result = {
      is_valid: true,
      errors: [],
      warnings: []
    }
    
    # Check airport code format
    unless valid_airport_code?(origin)
      validation_result[:is_valid] = false
      validation_result[:errors] << "Invalid origin airport code: #{origin}"
    end
    
    unless valid_airport_code?(destination)
      validation_result[:is_valid] = false
      validation_result[:errors] << "Invalid destination airport code: #{destination}"
    end
    
    # Check for impossible combinations
    if origin == destination && trip_type == 'round-trip'
      validation_result[:is_valid] = false
      validation_result[:errors] << "Round-trip flights cannot have same origin and destination"
    end
    
    # Check for known invalid routes
    if known_invalid_route?(origin, destination)
      validation_result[:warnings] << "Route #{origin}-#{destination} may not be serviced by commercial airlines"
    end
    
    validation_result
  end

  def validate_price_data(price_data, route, date)
    validation_result = {
      is_valid: true,
      errors: [],
      warnings: [],
      price_anomaly_score: 0.0
    }
    
    return validation_result unless price_data.is_a?(Hash)
    
    price = price_data['price'] || price_data[:price]
    
    if price.blank?
      validation_result[:is_valid] = false
      validation_result[:errors] << "Price is missing"
      return validation_result
    end
    
    # Convert to numeric
    begin
      numeric_price = price.to_f
    rescue
      validation_result[:is_valid] = false
      validation_result[:errors] << "Invalid price format: #{price}"
      return validation_result
    end
    
    # Check for extreme prices
    if numeric_price < 10
      validation_result[:warnings] << "Price #{numeric_price} seems unusually low"
      validation_result[:price_anomaly_score] += 0.3
    elsif numeric_price > 10000
      validation_result[:warnings] << "Price #{numeric_price} seems unusually high"
      validation_result[:price_anomaly_score] += 0.3
    end
    
    # Check against historical price range for this route
    historical_range = get_historical_price_range(route, date)
    if historical_range
      if numeric_price < historical_range[:min] * 0.5
        validation_result[:warnings] << "Price #{numeric_price} is significantly below historical minimum (#{historical_range[:min]})"
        validation_result[:price_anomaly_score] += 0.2
      elsif numeric_price > historical_range[:max] * 2
        validation_result[:warnings] << "Price #{numeric_price} is significantly above historical maximum (#{historical_range[:max]})"
        validation_result[:price_anomaly_score] += 0.2
      end
    end
    
    # Check currency
    currency = price_data['currency'] || price_data[:currency]
    if currency && !valid_currency_code?(currency)
      validation_result[:warnings] << "Invalid currency code: #{currency}"
    end
    
    validation_result
  end

  def validate_schedule_data(schedule_data)
    validation_result = {
      is_valid: true,
      errors: [],
      warnings: []
    }
    
    return validation_result unless schedule_data.is_a?(Hash)
    
    # Check departure time
    departure_time = schedule_data['departure_time'] || schedule_data[:departure_time]
    if departure_time
      unless valid_time_format?(departure_time)
        validation_result[:errors] << "Invalid departure time format: #{departure_time}"
        validation_result[:is_valid] = false
      end
    end
    
    # Check arrival time
    arrival_time = schedule_data['arrival_time'] || schedule_data[:arrival_time]
    if arrival_time
      unless valid_time_format?(arrival_time)
        validation_result[:errors] << "Invalid arrival time format: #{arrival_time}"
        validation_result[:is_valid] = false
      end
    end
    
    # Check flight duration if both times are present
    if departure_time && arrival_time && validation_result[:is_valid]
      begin
        dep_time = Time.parse(departure_time.to_s)
        arr_time = Time.parse(arrival_time.to_s)
        
        duration = (arr_time - dep_time) / 1.hour
        
        if duration < 0.5
          validation_result[:warnings] << "Flight duration #{duration.round(2)} hours seems unusually short"
        elsif duration > 24
          validation_result[:warnings] << "Flight duration #{duration.round(2)} hours seems unusually long"
        end
      rescue ArgumentError
        validation_result[:errors] << "Cannot calculate flight duration from provided times"
        validation_result[:is_valid] = false
      end
    end
    
    # Check flight number
    flight_number = schedule_data['flight_number'] || schedule_data[:flight_number]
    if flight_number && !valid_flight_number?(flight_number)
      validation_result[:warnings] << "Flight number format may be invalid: #{flight_number}"
    end
    
    # Check stops
    stops = schedule_data['stops'] || schedule_data[:stops]
    if stops
      stops_num = stops.to_i
      if stops_num < 0 || stops_num > 5
        validation_result[:warnings] << "Unusual number of stops: #{stops_num}"
      end
    end
    
    validation_result
  end

  def filter_invalid_data(flight_data, provider)
    validation_result = validate_flight_data(flight_data, provider)
    
    if validation_result[:success]
      # Return only valid flights
      valid_flights = []
      
      flight_data.each_with_index do |flight, index|
        if @validation_results[index][:is_valid]
          valid_flights << flight
        end
      end
      
      {
        success: true,
        original_count: flight_data.count,
        valid_count: valid_flights.count,
        filtered_count: flight_data.count - valid_flights.count,
        valid_flights: valid_flights,
        validation_summary: validation_result
      }
    else
      {
        success: false,
        errors: validation_result[:errors],
        validation_summary: validation_result
      }
    end
  end

  def calculate_data_quality_score(validation_results)
    return 0.0 if validation_results.empty?
    
    total_flights = validation_results.count
    valid_flights = validation_results.values.count { |r| r[:is_valid] }
    warning_flights = validation_results.values.count { |r| r[:warnings].any? }
    
    # Base score from validity
    base_score = valid_flights.to_f / total_flights
    
    # Reduce score for warnings
    warning_penalty = warning_flights.to_f / total_flights * 0.1
    
    # Calculate average anomaly score
    anomaly_scores = validation_results.values.map { |r| r[:price_anomaly_score] || 0.0 }
    average_anomaly = anomaly_scores.sum / anomaly_scores.count
    anomaly_penalty = average_anomaly * 0.2
    
    final_score = base_score - warning_penalty - anomaly_penalty
    [final_score, 0.0].max.round(2)
  end

  private

  def validate_single_flight(flight, provider)
    validation_result = {
      is_valid: true,
      errors: [],
      warnings: [],
      price_anomaly_score: 0.0
    }
    
    # Basic structure validation
    unless flight.is_a?(Hash)
      validation_result[:is_valid] = false
      validation_result[:errors] << "Flight data must be a hash"
      return validation_result
    end
    
    # Required fields validation
    required_fields = ['origin', 'destination', 'price']
    required_fields.each do |field|
      if flight[field].blank?
        validation_result[:is_valid] = false
        validation_result[:errors] << "Missing required field: #{field}"
      end
    end
    
    return validation_result unless validation_result[:is_valid]
    
    # Route validation
    route_validation = validate_route_validity(flight['origin'], flight['destination'], flight['trip_type'])
    if route_validation[:is_valid] == false
      validation_result[:is_valid] = false
      validation_result[:errors].concat(route_validation[:errors])
    end
    validation_result[:warnings].concat(route_validation[:warnings])
    
    # Price validation
    price_validation = validate_price_data(flight['pricing'] || flight, flight['route'], flight['date'])
    if price_validation[:is_valid] == false
      validation_result[:is_valid] = false
      validation_result[:errors].concat(price_validation[:errors])
    end
    validation_result[:warnings].concat(price_validation[:warnings])
    validation_result[:price_anomaly_score] = price_validation[:price_anomaly_score]
    
    # Schedule validation
    schedule_validation = validate_schedule_data(flight['schedule'] || flight)
    if schedule_validation[:is_valid] == false
      validation_result[:is_valid] = false
      validation_result[:errors].concat(schedule_validation[:errors])
    end
    validation_result[:warnings].concat(schedule_validation[:warnings])
    
    validation_result
  end

  def validate_dataset_consistency(flight_data, provider)
    # Check for duplicate flights
    duplicate_check = check_for_duplicates(flight_data)
    if duplicate_check[:duplicates_found]
      @warnings << "Found #{duplicate_check[:duplicate_count]} potential duplicate flights"
    end
    
    # Check for price consistency across similar routes
    price_consistency = check_price_consistency(flight_data)
    if price_consistency[:inconsistencies_found]
      @warnings << "Found #{price_consistency[:inconsistency_count]} price inconsistencies"
    end
  end

  def check_for_duplicates(flight_data)
    duplicates = []
    
    flight_data.each_with_index do |flight1, index1|
      flight_data[(index1 + 1)..-1].each_with_index do |flight2, index2|
        if flights_are_duplicates?(flight1, flight2)
          duplicates << { flight1_index: index1, flight2_index: index1 + index2 + 1 }
        end
      end
    end
    
    {
      duplicates_found: duplicates.any?,
      duplicate_count: duplicates.count,
      duplicate_details: duplicates
    }
  end

  def flights_are_duplicates?(flight1, flight2)
    # Check if two flights are essentially the same
    return false unless flight1['origin'] == flight2['origin']
    return false unless flight1['destination'] == flight2['destination']
    return false unless flight1['date'] == flight2['date']
    
    # Check if departure times are close
    if flight1['departure_time'] && flight2['departure_time']
      begin
        time1 = Time.parse(flight1['departure_time'].to_s)
        time2 = Time.parse(flight2['departure_time'].to_s)
        return false if (time1 - time2).abs > 30.minutes
      rescue ArgumentError
        return false
      end
    end
    
    # Check if prices are similar
    if flight1['price'] && flight2['price']
      price1 = flight1['price'].to_f
      price2 = flight2['price'].to_f
      return false if price1 == 0 || price2 == 0
      
      price_diff = (price1 - price2).abs / [price1, price2].max
      return false if price_diff > 0.1 # More than 10% difference
    end
    
    true
  end

  def check_price_consistency(flight_data)
    inconsistencies = []
    
    # Group flights by route
    flights_by_route = flight_data.group_by { |f| "#{f['origin']}-#{f['destination']}" }
    
    flights_by_route.each do |route, flights|
      prices = flights.map { |f| f['price'] || f.dig('pricing', 'price') }.compact.map(&:to_f)
      next if prices.length < 2
      
      # Check for extreme price variations
      min_price = prices.min
      max_price = prices.max
      
      if min_price > 0 && max_price > 0
        variation = (max_price - min_price) / min_price
        
        if variation > 2.0 # More than 200% variation
          inconsistencies << {
            route: route,
            min_price: min_price,
            max_price: max_price,
            variation: variation
          }
        end
      end
    end
    
    {
      inconsistencies_found: inconsistencies.any?,
      inconsistency_count: inconsistencies.count,
      inconsistency_details: inconsistencies
    }
  end

  def valid_airport_code?(code)
    return false if code.blank?
    code.to_s.match?(/^[A-Z]{3}$/)
  end

  def valid_currency_code?(currency)
    return false if currency.blank?
    currency.to_s.match?(/^[A-Z]{3}$/)
  end

  def valid_time_format?(time)
    return false if time.blank?
    
    begin
      Time.parse(time.to_s)
      true
    rescue ArgumentError
      false
    end
  end

  def valid_flight_number?(flight_number)
    return false if flight_number.blank?
    
    # Basic flight number validation (airline code + numbers)
    flight_number.to_s.match?(/^[A-Z]{2,3}\d{1,4}$/)
  end

  def known_invalid_route?(origin, destination)
    # This could be expanded with a database of known invalid routes
    # For now, just check for some obvious cases
    invalid_routes = [
      ['XXX', 'YYY'], # Example invalid route
      ['ZZZ', 'AAA']  # Example invalid route
    ]
    
    invalid_routes.include?([origin, destination])
  end

  def get_historical_price_range(route, date)
    # This would query the FlightPriceHistory model
    # For now, return nil (no historical data available)
    nil
  end
end
