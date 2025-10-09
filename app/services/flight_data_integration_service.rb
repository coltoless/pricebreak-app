class FlightDataIntegrationService
  include ActiveModel::Validations

  attr_reader :errors, :processed_count, :duplicate_count, :invalid_count

  def initialize
    @errors = []
    @processed_count = 0
    @duplicate_count = 0
    @invalid_count = 0
  end

  def normalize_and_store_flight_data(raw_data, provider)
    return { success: false, errors: ['No data provided'] } if raw_data.blank?
    
    @processed_count = 0
    @duplicate_count = 0
    @invalid_count = 0
    @errors = []
    
    begin
      # Normalize the raw data
      normalized_data = normalize_flight_data(raw_data, provider)
      
      # Store in FlightProviderData
      store_provider_data(normalized_data, provider)
      
      # Store price history
      store_price_history(normalized_data, provider)
      
      # Detect and handle duplicates
      handle_duplicates(provider)
      
      { 
        success: true, 
        processed: @processed_count,
        duplicates: @duplicate_count,
        invalid: @invalid_count,
        errors: @errors
      }
    rescue => e
      @errors << "Integration error: #{e.message}"
      { success: false, errors: @errors }
    end
  end

  def merge_provider_data(primary_provider, fallback_providers = [])
    results = { merged: 0, errors: [] }
    
    begin
      # Get data from primary provider
      primary_data = FlightProviderDatum.by_provider(primary_provider).valid_data
      
      fallback_providers.each do |fallback_provider|
        fallback_data = FlightProviderDatum.by_provider(fallback_provider).valid_data
        
        fallback_data.each do |fallback_record|
          # Find matching primary record
          matching_primary = find_matching_flight(primary_data, fallback_record)
          
          if matching_primary
            # Merge data, keeping primary as source of truth
            merge_flight_records(matching_primary, fallback_record)
            results[:merged] += 1
          else
            # Create new record from fallback
            create_from_fallback(fallback_record, primary_provider)
            results[:merged] += 1
          end
        end
      end
      
      results
    rescue => e
      results[:errors] << "Merge error: #{e.message}"
      results
    end
  end

  def validate_data_quality(provider = nil, hours = 24)
    scope = FlightProviderDatum.where('data_timestamp >= ?', Time.current - hours.hours)
    scope = scope.by_provider(provider) if provider
    
    quality_metrics = {
      total_records: scope.count,
      valid_records: scope.valid_data.count,
      suspicious_records: scope.by_status('suspicious').count,
      invalid_records: scope.by_status('invalid').count,
      duplicate_groups: scope.where.not(duplicate_group_id: nil).distinct.count(:duplicate_group_id),
      data_freshness: calculate_data_freshness(scope),
      price_anomalies: detect_price_anomalies(scope),
      route_coverage: calculate_route_coverage(scope)
    }
    
    quality_metrics[:quality_score] = calculate_overall_quality_score(quality_metrics)
    quality_metrics
  end

  def cleanup_stale_data(providers = nil, max_age_hours = 24)
    scope = FlightProviderDatum.where('data_timestamp < ?', Time.current - max_age_hours.hours)
    scope = scope.by_provider(providers) if providers
    
    stale_count = scope.count
    
    # Archive before deletion (optional)
    archive_stale_data(scope) if stale_count > 0
    
    # Delete stale records
    deleted_count = scope.delete_all
    
    Rails.logger.info "Cleaned up #{deleted_count} stale flight provider data records"
    
    { deleted: deleted_count, archived: stale_count }
  end

  private

  def normalize_flight_data(raw_data, provider)
    normalized = []
    
    Array(raw_data).each do |flight|
      begin
        normalized_flight = normalize_single_flight(flight, provider)
        normalized << normalized_flight if normalized_flight
      rescue => e
        @errors << "Failed to normalize flight: #{e.message}"
        @invalid_count += 1
      end
    end
    
    normalized
  end

  def normalize_single_flight(flight, provider)
    return nil unless flight.is_a?(Hash)
    
    # Extract and normalize basic flight information
    normalized = {
      flight_identifier: extract_flight_identifier(flight, provider),
      route: normalize_route(flight),
      schedule: normalize_schedule(flight),
      pricing: normalize_pricing(flight),
      data_timestamp: Time.current
    }
    
    # Validate normalized data
    if valid_normalized_flight?(normalized)
      normalized
    else
      @invalid_count += 1
      nil
    end
  end

  def extract_flight_identifier(flight, provider)
    # Try different possible identifier fields
    identifier = flight['id'] || flight['flight_id'] || flight['identifier'] || 
                flight['flight_number'] || flight['booking_reference']
    
    # If no identifier, create one from available data
    if identifier.blank?
      airline = flight.dig('airline', 'code') || flight['carrier'] || 'UNK'
      flight_num = flight['flight_number'] || '000'
      route = normalize_route(flight)
      identifier = "#{airline}#{flight_num}_#{route}_#{provider}"
    end
    
    identifier.to_s.strip
  end

  def normalize_route(flight)
    origin = flight['origin'] || flight['departure'] || flight['from']
    destination = flight['destination'] || flight['arrival'] || flight['to']
    
    return nil if origin.blank? || destination.blank?
    
    # Normalize airport codes
    origin_code = normalize_airport_code(origin)
    dest_code = normalize_airport_code(destination)
    
    "#{origin_code}-#{dest_code}"
  end

  def normalize_airport_code(airport)
    return airport.to_s.strip.upcase if airport.to_s.match?(/^[A-Z]{3}$/)
    
    # Try to extract code from various formats
    if airport.is_a?(Hash)
      airport['code'] || airport['iata'] || airport['icao']
    elsif airport.to_s.match?(/^[A-Z]{3}\s*\([A-Z]{3}\)$/)
      airport.to_s.match(/^([A-Z]{3})/)[1]
    else
      airport.to_s.strip.upcase
    end
  end

  def normalize_schedule(flight)
    schedule = {}
    
    # Departure time
    if flight['departure_time']
      schedule['departure_time'] = normalize_time(flight['departure_time'])
    end
    
    # Arrival time
    if flight['arrival_time']
      schedule['arrival_time'] = normalize_time(flight['arrival_time'])
    end
    
    # Flight date
    if flight['departure_date'] || flight['date']
      schedule['date'] = normalize_date(flight['departure_date'] || flight['date'])
    end
    
    # Airline information
    if flight['airline']
      airline = flight['airline']
      if airline.is_a?(Hash)
        schedule['airline'] = airline['name'] || airline['code']
        schedule['airline_code'] = airline['code']
      else
        schedule['airline'] = airline
      end
    end
    
    # Flight number
    if flight['flight_number']
      schedule['flight_number'] = flight['flight_number'].to_s.strip
    end
    
    # Stops information
    if flight['stops'] || flight['stop_count']
      stops = flight['stops'] || flight['stop_count']
      schedule['stops'] = stops.to_i
    end
    
    schedule
  end

  def normalize_pricing(flight)
    pricing = {}
    
    # Price
    if flight['price'] || flight['amount'] || flight['cost']
      price = flight['price'] || flight['amount'] || flight['cost']
      pricing['price'] = normalize_price(price)
    end
    
    # Currency
    if flight['currency']
      pricing['currency'] = flight['currency'].to_s.strip.upcase
    else
      pricing['currency'] = 'USD' # Default currency
    end
    
    # Booking class
    if flight['cabin_class'] || flight['class']
      pricing['cabin_class'] = normalize_cabin_class(flight['cabin_class'] || flight['class'])
    end
    
    # Fare type
    if flight['fare_type'] || flight['ticket_type']
      pricing['fare_type'] = flight['fare_type'] || flight['ticket_type']
    end
    
    pricing
  end

  def normalize_time(time_value)
    return nil if time_value.blank?
    
    begin
      parsed_time = Time.parse(time_value.to_s)
      parsed_time.iso8601
    rescue ArgumentError
      time_value.to_s.strip
    end
  end

  def normalize_date(date_value)
    return nil if date_value.blank?
    
    begin
      parsed_date = Date.parse(date_value.to_s)
      parsed_date.iso8601
    rescue ArgumentError
      date_value.to_s.strip
    end
  end

  def normalize_price(price_value)
    return nil if price_value.blank?
    
    begin
      # Remove currency symbols and convert to decimal
      clean_price = price_value.to_s.gsub(/[^\d.,]/, '')
      BigDecimal(clean_price)
    rescue ArgumentError
      nil
    end
  end

  def normalize_cabin_class(cabin_class)
    return 'economy' if cabin_class.blank?
    
    cabin = cabin_class.to_s.strip.downcase
    
    case cabin
    when /economy|coach|y/
      'economy'
    when /premium.?economy|w/
      'premium-economy'
    when /business|b/
      'business'
    when /first|f/
      'first'
    else
      'economy'
    end
  end

  def valid_normalized_flight?(normalized)
    return false if normalized[:flight_identifier].blank?
    return false if normalized[:route].blank?
    return false if normalized[:schedule].blank?
    return false if normalized[:pricing].blank?
    
    # Must have at least departure time or date
    schedule = normalized[:schedule]
    return false if schedule['departure_time'].blank? && schedule['date'].blank?
    
    # Must have price
    pricing = normalized[:pricing]
    return false if pricing['price'].blank?
    
    true
  end

  def store_provider_data(normalized_data, provider)
    normalized_data.each do |flight_data|
      begin
        # Check for existing record
        existing = FlightProviderDatum.find_by(
          flight_identifier: flight_data[:flight_identifier],
          provider: provider
        )
        
        if existing
          # Update existing record
          existing.update!(
            route: flight_data[:route],
            schedule: flight_data[:schedule],
            pricing: flight_data[:pricing],
            data_timestamp: flight_data[:data_timestamp],
            validation_status: 'pending'
          )
        else
          # Create new record
          FlightProviderDatum.create!(
            flight_identifier: flight_data[:flight_identifier],
            provider: provider,
            route: flight_data[:route],
            schedule: flight_data[:schedule],
            pricing: flight_data[:pricing],
            data_timestamp: flight_data[:data_timestamp]
          )
        end
        
        @processed_count += 1
      rescue => e
        @errors << "Failed to store flight data: #{e.message}"
        @invalid_count += 1
      end
    end
  end

  def store_price_history(normalized_data, provider)
    normalized_data.each do |flight_data|
      begin
        schedule = flight_data[:schedule]
        pricing = flight_data[:pricing]
        
        next unless schedule['date'] && pricing['price']
        
        # Create or update price history
        FlightPriceHistory.find_or_create_by(
          route: flight_data[:route],
          date: Date.parse(schedule['date']),
          provider: provider,
          booking_class: pricing['cabin_class'] || 'economy'
        ) do |history|
          history.price = pricing['price']
          history.timestamp = flight_data[:data_timestamp]
        end
        
        # Update existing record if price changed
        existing = FlightPriceHistory.find_by(
          route: flight_data[:route],
          date: Date.parse(schedule['date']),
          provider: provider,
          booking_class: pricing['cabin_class'] || 'economy'
        )
        
        if existing && existing.price != pricing['price']
          existing.update!(
            price: pricing['price'],
            timestamp: flight_data[:data_timestamp]
          )
        end
      rescue => e
        @errors << "Failed to store price history: #{e.message}"
      end
    end
  end

  def handle_duplicates(provider)
    # Find records that might be duplicates
    recent_records = FlightProviderDatum.by_provider(provider)
                                     .where('data_timestamp >= ?', 1.hour.ago)
                                     .where(duplicate_group_id: nil)
    
    recent_records.each do |record|
      # Find similar records
      similar_records = find_similar_records(record)
      
      if similar_records.count > 1
        # Group them together
        group_id = record.id
        similar_records.update_all(duplicate_group_id: group_id)
        @duplicate_count += similar_records.count
      end
    end
  end

  def find_similar_records(record)
    FlightProviderDatum.where(route: record.route)
                      .where(provider: record.provider)
                      .where('data_timestamp >= ?', 1.hour.ago)
                      .where('ABS(EXTRACT(EPOCH FROM (data_timestamp - ?)) / 3600) < 2', record.data_timestamp)
  end

  def find_matching_flight(primary_data, fallback_record)
    primary_data.find do |primary|
      primary.route == fallback_record.route &&
      primary.schedule['date'] == fallback_record.schedule['date'] &&
      primary.schedule['departure_time'] == fallback_record.schedule['departure_time']
    end
  end

  def merge_flight_records(primary, fallback)
    # Merge additional information from fallback
    merged_schedule = primary.schedule.merge(fallback.schedule) { |key, primary_val, fallback_val| primary_val }
    merged_pricing = primary.pricing.merge(fallback.pricing) { |key, primary_val, fallback_val| primary_val }
    
    primary.update!(
      schedule: merged_schedule,
      pricing: merged_pricing,
      data_timestamp: [primary.data_timestamp, fallback.data_timestamp].max
    )
  end

  def create_from_fallback(fallback_record, primary_provider)
    # Create new record in primary provider's data
    FlightProviderDatum.create!(
      flight_identifier: "#{fallback_record.flight_identifier}_#{primary_provider}",
      provider: primary_provider,
      route: fallback_record.route,
      schedule: fallback_record.schedule,
      pricing: fallback_record.pricing,
      data_timestamp: fallback_record.data_timestamp
    )
  end

  def calculate_data_freshness(scope)
    recent_records = scope.where('data_timestamp >= ?', 1.hour.ago).count
  end

  def detect_price_anomalies(scope)
    anomalies = []
    
    scope.valid_data.find_each do |record|
      price = record.extract_price
      next unless price.is_a?(Numeric)
      
      if price < 10 || price > 10000
        anomalies << {
          record_id: record.id,
          price: price,
          type: 'extreme_price'
        }
      end
    end
    
    anomalies
  end

  def calculate_route_coverage(scope)
    unique_routes = scope.distinct.count(:route)
    total_possible_routes = 1000 # Approximate number of major routes
    
    (unique_routes.to_f / total_possible_routes * 100).round(2)
  end

  def calculate_overall_quality_score(metrics)
    score = 0.0
    
    # Data validity score
    if metrics[:total_records] > 0
      validity_score = metrics[:valid_records].to_f / metrics[:total_records]
      score += validity_score * 0.4
    end
    
    # Data freshness score
    freshness_score = [metrics[:data_freshness].to_f / 100, 1.0].min
    score += freshness_score * 0.3
    
    # Route coverage score
    coverage_score = metrics[:route_coverage] / 100.0
    score += coverage_score * 0.2
    
    # Duplicate handling score
    duplicate_score = metrics[:duplicate_groups] > 0 ? 0.8 : 1.0
    score += duplicate_score * 0.1
    
    score.round(2)
  end

  def archive_stale_data(scope)
    # This could be implemented to archive data before deletion
    # For now, just log the action
    Rails.logger.info "Archiving #{scope.count} stale flight provider data records"
  end
end
