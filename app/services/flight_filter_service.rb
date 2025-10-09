class FlightFilterService
  include ActiveModel::Validations

  attr_reader :flight_filter, :errors

  def initialize(flight_filter = nil)
    @flight_filter = flight_filter
    @errors = []
  end

  def create_filter(params, user = nil)
    @flight_filter = FlightFilter.new(params)
    @flight_filter.user = user if user
    
    if validate_filter_creation && @flight_filter.save
      create_associated_alert
      { success: true, filter: @flight_filter }
    else
      { success: false, errors: @flight_filter.errors.full_messages + @errors }
    end
  end

  def update_filter(filter_id, params)
    @flight_filter = FlightFilter.find(filter_id)
    
    if validate_filter_update(params) && @flight_filter.update(params)
      update_associated_alert
      { success: true, filter: @flight_filter }
    else
      { success: false, errors: @flight_filter.errors.full_messages + @errors }
    end
  end

  def duplicate_filter(filter_id, user = nil)
    original = FlightFilter.find(filter_id)
    duplicate = original.dup
    
    # Modify the duplicate
    duplicate.name = "#{original.name} (Copy)"
    duplicate.is_active = false
    duplicate.user = user if user
    
    if duplicate.save
      { success: true, filter: duplicate }
    else
      { success: false, errors: duplicate.errors.full_messages }
    end
  end

  def bulk_operations(filter_ids, operations)
    filters = FlightFilter.where(id: filter_ids)
    results = { success: [], failed: [] }
    
    operations.each do |operation, value|
      filters.each do |filter|
        begin
          case operation
          when :activate
            filter.update!(is_active: value)
          when :deactivate
            filter.update!(is_active: value)
          when :delete
            filter.destroy!
          end
          results[:success] << filter.id
        rescue => e
          results[:failed] << { id: filter.id, error: e.message }
        end
      end
    end
    
    results
  end

  def validate_route_combination(origin_airports, destination_airports, trip_type)
    # Check for impossible combinations
    origins = Array(origin_airports)
    destinations = Array(destination_airports)
    
    # Same origin and destination for round-trip
    if trip_type == 'round-trip' && origins == destinations
      @errors << "Round-trip flights cannot have same origin and destination"
      return false
    end
    
    # Check for valid airport codes (basic validation)
    origins.each do |origin|
      unless valid_airport_code?(origin)
        @errors << "Invalid origin airport code: #{origin}"
        return false
      end
    end
    
    destinations.each do |destination|
      unless valid_airport_code?(destination)
        @errors << "Invalid destination airport code: #{destination}"
        return false
      end
    end
    
    true
  end

  def detect_duplicate_filters(user_id, filter_params)
    return [] unless user_id
    
    FlightFilter.where(user_id: user_id)
               .where(origin_airports: filter_params[:origin_airports])
               .where(destination_airports: filter_params[:destination_airports])
               .where(trip_type: filter_params[:trip_type])
               .where.not(id: @flight_filter&.id)
  end

  def calculate_monitoring_priority(filter)
    priority = 0
    
    # Higher priority for urgent trips
    if filter.is_urgent?
      priority += 100
    end
    
    # Higher priority for more specific filters
    if filter.advanced_preferences&.dig('airline_preferences')&.any?
      priority += 20
    end
    
    if filter.advanced_preferences&.dig('max_stops') != 'any'
      priority += 15
    end
    
    # Higher priority for higher value trips
    if filter.max_price && filter.max_price > 1000
      priority += 10
    end
    
    priority
  end

  def optimize_monitoring_schedule(filter)
    priority = calculate_monitoring_priority(filter)
    
    case
    when priority >= 100
      { frequency: 'hourly', next_check: 1.hour.from_now }
    when priority >= 50
      { frequency: 'every_3_hours', next_check: 3.hours.from_now }
    when priority >= 20
      { frequency: 'every_6_hours', next_check: 6.hours.from_now }
    else
      { frequency: 'daily', next_check: 1.day.from_now }
    end
  end

  private

  def validate_filter_creation
    validate_basic_requirements
    validate_route_combination(@flight_filter.origin_airports, @flight_filter.destination_airports, @flight_filter.trip_type)
    validate_date_logic
    validate_passenger_logic
    validate_price_logic
    
    @errors.empty?
  end

  def validate_filter_update(params)
    # For updates, only validate what's being changed
    if params[:origin_airports] || params[:destination_airports] || params[:trip_type]
      validate_route_combination(
        params[:origin_airports] || @flight_filter.origin_airports,
        params[:destination_airports] || @flight_filter.destination_airports,
        params[:trip_type] || @flight_filter.trip_type
      )
    end
    
    if params[:departure_dates] || params[:return_dates]
      validate_date_logic
    end
    
    @errors.empty?
  end

  def validate_basic_requirements
    if @flight_filter.name.blank?
      @errors << "Filter name is required"
    end
    
    if @flight_filter.origin_airports.blank?
      @errors << "Origin airports are required"
    end
    
    if @flight_filter.destination_airports.blank?
      @errors << "Destination airports are required"
    end
    
    if @flight_filter.trip_type.blank?
      @errors << "Trip type is required"
    end
  end

  def validate_date_logic
    departure_dates = @flight_filter.departure_dates_array
    return_dates = @flight_filter.return_dates_array
    
    # Check if departure dates are in the future
    departure_dates.each do |date_str|
      begin
        date = Date.parse(date_str)
        if date < Date.current
          @errors << "Departure date #{date_str} cannot be in the past"
        end
      rescue ArgumentError
        @errors << "Invalid departure date format: #{date_str}"
      end
    end
    
    # For round-trip, validate return dates
    if @flight_filter.trip_type == 'round-trip' && return_dates.any?
      departure_dates.each do |dep_date_str|
        return_dates.each do |ret_date_str|
          begin
            dep_date = Date.parse(dep_date_str)
            ret_date = Date.parse(ret_date_str)
            
            if ret_date <= dep_date
              @errors << "Return date must be after departure date"
            end
          rescue ArgumentError
            @errors << "Invalid date format in round-trip"
          end
        end
      end
    end
  end

  def validate_passenger_logic
    details = @flight_filter.passenger_details
    return unless details.is_a?(Hash)
    
    adults = details['adults'] || 0
    children = details['children'] || 0
    infants = details['infants'] || 0
    
    if adults < 1
      @errors << "At least one adult passenger is required"
    end
    
    if infants > adults
      @errors << "Cannot have more infants than adults"
    end
    
    total = adults + children + infants
    if total > 9
      @errors << "Maximum 9 passengers allowed per filter"
    end
  end

  def validate_price_logic
    params = @flight_filter.price_parameters
    return unless params.is_a?(Hash)
    
    min_price = params['min_price'] || 0
    max_price = params['max_price'] || 10000
    target_price = params['target_price'] || 0
    
    if min_price >= max_price
      @errors << "Minimum price must be less than maximum price"
    end
    
    if target_price < min_price || target_price > max_price
      @errors << "Target price must be within min/max range"
    end
    
    if max_price > 50000
      @errors << "Maximum price cannot exceed $50,000"
    end
  end

  def valid_airport_code?(code)
    return false if code.blank?
    code.to_s.match?(/^[A-Z]{3}$/)
  end

  def create_associated_alert
    return unless @flight_filter.flight_alerts.empty?
    
    alert = @flight_filter.flight_alerts.build(
      origin: @flight_filter.origin_airports_array.first,
      destination: @flight_filter.destination_airports_array.first,
      departure_date: @flight_filter.departure_dates_array.first,
      return_date: @flight_filter.return_dates_array.first,
      passengers: @flight_filter.passenger_count,
      cabin_class: @flight_filter.cabin_class,
      target_price: @flight_filter.target_price,
      notification_method: 'email',
      status: 'active'
    )
    
    alert.save!
  end

  def update_associated_alert
    return unless @flight_filter.flight_alerts.any?
    
    alert = @flight_filter.flight_alerts.first
    alert.update!(
      origin: @flight_filter.origin_airports_array.first,
      destination: @flight_filter.destination_airports_array.first,
      departure_date: @flight_filter.departure_dates_array.first,
      return_date: @flight_filter.return_dates_array.first,
      passengers: @flight_filter.passenger_count,
      cabin_class: @flight_filter.cabin_class,
      target_price: @flight_filter.target_price
    )
  end
end
