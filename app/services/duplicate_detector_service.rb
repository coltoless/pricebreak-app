class DuplicateDetectorService
  include ActiveModel::Validations

  attr_reader :duplicates_found, :merged_count, :errors

  def initialize
    @duplicates_found = 0
    @merged_count = 0
    @errors = []
  end

  def detect_and_merge_duplicates(provider = nil, hours = 24)
    @duplicates_found = 0
    @merged_count = 0
    @errors = []
    
    begin
      # Find potential duplicates
      potential_duplicates = find_potential_duplicates(provider, hours)
      
      # Group and merge duplicates
      potential_duplicates.each do |group|
        merge_duplicate_group(group)
      end
      
      { 
        success: true, 
        duplicates_found: @duplicates_found,
        merged_count: @merged_count,
        errors: @errors
      }
    rescue => e
      @errors << "Duplicate detection error: #{e.message}"
      { success: false, errors: @errors }
    end
  end

  def detect_cross_provider_duplicates(hours = 24)
    @duplicates_found = 0
    @merged_count = 0
    @errors = []
    
    begin
      # Find duplicates across different providers
      cross_provider_duplicates = find_cross_provider_duplicates(hours)
      
      # Group and merge cross-provider duplicates
      cross_provider_duplicates.each do |group|
        merge_cross_provider_group(group)
      end
      
      { 
        success: true, 
        duplicates_found: @duplicates_found,
        merged_count: @merged_count,
        errors: @errors
      }
    rescue => e
      @errors << "Cross-provider duplicate detection error: #{e.message}"
      { success: false, errors: @errors }
    end
  end

  def find_duplicates_for_route(route, provider = nil, date_range = nil)
    scope = FlightProviderDatum.where(route: route)
    scope = scope.by_provider(provider) if provider
    scope = scope.by_date_range(date_range.begin, date_range.end) if date_range
    
    # Group by similarity
    grouped_duplicates = group_by_similarity(scope)
    
    # Return groups with more than one record
    grouped_duplicates.select { |group| group.count > 1 }
  end

  def merge_specific_duplicates(duplicate_group_ids)
    @merged_count = 0
    @errors = []
    
    duplicate_group_ids.each do |group_id|
      begin
        group = FlightProviderDatum.where(duplicate_group_id: group_id)
        merge_duplicate_group(group.to_a)
      rescue => e
        @errors << "Failed to merge group #{group_id}: #{e.message}"
      end
    end
    
    { merged_count: @merged_count, errors: @errors }
  end

  def validate_duplicate_merge(record1, record2)
    # Check if two records are actually duplicates
    similarity_score = calculate_similarity_score(record1, record2)
    
    {
      are_duplicates: similarity_score >= 0.8,
      similarity_score: similarity_score,
      confidence: determine_confidence_level(similarity_score),
      merge_recommendation: similarity_score >= 0.8 ? 'merge' : 'keep_separate'
    }
  end

  def find_flight_matches(flight_data, provider = nil, threshold = 0.8)
    # Find existing flights that match the given flight data
    scope = FlightProviderDatum.all
    scope = scope.by_provider(provider) if provider
    
    matches = []
    
    scope.find_each do |existing_flight|
      similarity = calculate_flight_similarity(flight_data, existing_flight)
      if similarity >= threshold
        matches << {
          flight: existing_flight,
          similarity: similarity,
          confidence: determine_confidence_level(similarity)
        }
      end
    end
    
    # Sort by similarity score
    matches.sort_by { |match| -match[:similarity] }
  end

  private

  def find_potential_duplicates(provider, hours)
    scope = FlightProviderDatum.where('data_timestamp >= ?', Time.current - hours.hours)
    scope = scope.by_provider(provider) if provider
    
    # Group by route and time proximity
    grouped_records = scope.group(:route).having('COUNT(*) > 1')
    
    potential_duplicates = []
    
    grouped_records.each do |route_group|
      route_records = scope.where(route: route_group.route).order(:data_timestamp)
      
      # Find records within time proximity
      time_groups = group_by_time_proximity(route_records)
      
      time_groups.each do |time_group|
        if time_group.count > 1
          potential_duplicates << time_group
        end
      end
    end
    
    potential_duplicates
  end

  def find_cross_provider_duplicates(hours)
    # Find duplicates across different providers for the same flights
    scope = FlightProviderDatum.where('data_timestamp >= ?', Time.current - hours.hours)
    
    # Group by route, date, and airline to find potential cross-provider duplicates
    grouped_records = scope.group(:route, :departure_date, :airline_code).having('COUNT(*) > 1')
    
    cross_provider_duplicates = []
    
    grouped_records.each do |group|
      route_records = scope.where(
        route: group.route,
        departure_date: group.departure_date,
        airline_code: group.airline_code
      ).order(:data_timestamp)
      
      # Check if records are from different providers
      providers = route_records.pluck(:provider).uniq
      if providers.length > 1
        cross_provider_duplicates << route_records.to_a
      end
    end
    
    cross_provider_duplicates
  end

  def merge_cross_provider_group(group)
    return if group.length < 2
    
    # Sort by data quality and recency
    sorted_group = group.sort_by { |record| [-record.data_quality_score, -record.data_timestamp.to_i] }
    primary_record = sorted_group.first
    duplicate_records = sorted_group[1..-1]
    
    begin
      # Update primary record with best data from duplicates
      enhanced_primary = enhance_primary_record(primary_record, duplicate_records)
      
      # Mark duplicates for deletion
      duplicate_records.each do |duplicate|
        duplicate.update!(
          duplicate_group_id: primary_record.id,
          status: 'duplicate',
          merged_into: primary_record.id
        )
      end
      
      # Update primary record
      primary_record.update!(
        data_quality_score: enhanced_primary[:data_quality_score],
        price_confidence: enhanced_primary[:price_confidence],
        last_merged_at: Time.current
      )
      
      @merged_count += duplicate_records.length
      @duplicates_found += 1
      
    rescue => e
      @errors << "Failed to merge cross-provider group: #{e.message}"
    end
  end

  def enhance_primary_record(primary, duplicates)
    enhanced = {
      data_quality_score: primary.data_quality_score,
      price_confidence: primary.price_confidence
    }
    
    # Enhance with data from duplicates
    duplicates.each do |duplicate|
      # Improve data quality score if duplicate has better data
      if duplicate.data_quality_score > enhanced[:data_quality_score]
        enhanced[:data_quality_score] = duplicate.data_quality_score
      end
      
      # Improve price confidence if duplicate has more recent price
      if duplicate.data_timestamp > primary.data_timestamp && duplicate.price_confidence
        enhanced[:price_confidence] = duplicate.price_confidence
      end
    end
    
    enhanced
  end

  def calculate_flight_similarity(flight1, flight2)
    # Enhanced similarity calculation for cross-provider matching
    scores = []
    
    # Route similarity (highest weight)
    if flight1[:route] == flight2.route
      scores << 1.0
    elsif normalize_route(flight1[:route]) == normalize_route(flight2.route)
      scores << 0.9
    else
      scores << 0.0
    end
    
    # Date similarity
    if flight1[:departure_date] && flight2.departure_date
      date_diff = (flight1[:departure_date].to_date - flight2.departure_date.to_date).abs
      if date_diff == 0
        scores << 1.0
      elsif date_diff <= 1
        scores << 0.8
      elsif date_diff <= 3
        scores << 0.6
      else
        scores << 0.0
      end
    end
    
    # Airline similarity
    if flight1[:airline] && flight2.airline_code
      airline1 = normalize_airline(flight1[:airline])
      airline2 = normalize_airline(flight2.airline_code)
      
      if airline1 == airline2
        scores << 1.0
      elsif airline1 && airline2 && (airline1.include?(airline2) || airline2.include?(airline1))
        scores << 0.8
      else
        scores << 0.0
      end
    end
    
    # Flight number similarity
    if flight1[:flight_number] && flight2.flight_number
      if flight1[:flight_number].to_s == flight2.flight_number.to_s
        scores << 1.0
      else
        scores << 0.0
      end
    end
    
    # Cabin class similarity
    if flight1[:cabin_class] && flight2.cabin_class
      cabin1 = normalize_cabin_class(flight1[:cabin_class])
      cabin2 = normalize_cabin_class(flight2.cabin_class)
      
      if cabin1 == cabin2
        scores << 1.0
      elsif cabin1 == 'economy' && cabin2 == 'economy'
        scores << 0.9
      else
        scores << 0.5
      end
    end
    
    # Price similarity (lower weight to account for variations)
    if flight1[:price] && flight2.price
      price_diff = (flight1[:price] - flight2.price).abs
      price_ratio = price_diff / [flight1[:price], flight2.price].max
      
      if price_ratio <= 0.1
        scores << 1.0
      elsif price_ratio <= 0.2
        scores << 0.8
      elsif price_ratio <= 0.3
        scores << 0.6
      else
        scores << 0.0
      end
    end
    
    # Calculate weighted average
    weights = [0.4, 0.25, 0.15, 0.1, 0.05, 0.05] # Route, Date, Airline, Flight#, Cabin, Price
    weighted_score = scores.zip(weights).sum { |score, weight| score * weight }
    
    weighted_score
  end

  def normalize_route(route)
    return nil unless route
    
    # Normalize route format (e.g., "LAX-JFK" or "LAX to JFK")
    route.to_s.upcase.gsub(/[^A-Z0-9]/, '-').gsub(/-+/, '-').chomp('-')
  end

  def normalize_airline(airline)
    return nil unless airline
    
    if airline.is_a?(Hash)
      airline[:code] || airline[:name]
    else
      airline.to_s.upcase
    end
  end

  def normalize_cabin_class(cabin_class)
    return nil unless cabin_class
    
    case cabin_class.to_s.downcase
    when 'economy', 'coach', 'y', 'm', 'k'
      'economy'
    when 'premium_economy', 'premium', 'w', 'e'
      'premium_economy'
    when 'business', 'c', 'd', 'j'
      'business'
    when 'first', 'f', 'a'
      'first'
    else
      'economy'
    end
  end

  def group_by_time_proximity(records, time_threshold = 2.hours)
    groups = []
    current_group = []
    
    records.each do |record|
      if current_group.empty?
        current_group << record
      else
        # Check if this record is within time threshold of the first record in current group
        time_diff = (record.data_timestamp - current_group.first.data_timestamp).abs
        
        if time_diff <= time_threshold
          current_group << record
        else
          groups << current_group if current_group.count > 1
          current_group = [record]
        end
      end
    end
    
    groups << current_group if current_group.count > 1
    groups
  end

  def group_by_similarity(records)
    groups = []
    processed_ids = Set.new
    
    records.each do |record|
      next if processed_ids.include?(record.id)
      
      similar_records = find_similar_records(record, records)
      
      if similar_records.count > 1
        groups << similar_records
        similar_records.each { |r| processed_ids.add(r.id) }
      end
    end
    
    groups
  end

  def find_similar_records(record, all_records)
    similar = [record]
    
    all_records.where.not(id: record.id).each do |other_record|
      if records_are_similar?(record, other_record)
        similar << other_record
      end
    end
    
    similar
  end

  def records_are_similar?(record1, record2)
    # Check basic attributes
    return false unless record1.route == record2.route
    return false unless record1.provider == record2.provider
    
    # Check time proximity
    time_diff = (record1.data_timestamp - record2.data_timestamp).abs
    return false if time_diff > 2.hours
    
    # Check schedule similarity
    schedule_similarity = compare_schedules(record1.schedule, record2.schedule)
    return false if schedule_similarity < 0.7
    
    # Check pricing similarity
    pricing_similarity = compare_pricing(record1.pricing, record2.pricing)
    return false if pricing_similarity < 0.6
    
    true
  end

  def compare_schedules(schedule1, schedule2)
    return 0.0 unless schedule1.is_a?(Hash) && schedule2.is_a?(Hash)
    
    score = 0.0
    total_checks = 0
    
    # Compare departure time
    if schedule1['departure_time'] && schedule2['departure_time']
      time1 = parse_time(schedule1['departure_time'])
      time2 = parse_time(schedule2['departure_time'])
      
      if time1 && time2
        time_diff = (time1 - time2).abs
        score += time_diff <= 30.minutes ? 1.0 : 0.5
        total_checks += 1
      end
    end
    
    # Compare arrival time
    if schedule1['arrival_time'] && schedule2['arrival_time']
      time1 = parse_time(schedule1['arrival_time'])
      time2 = parse_time(schedule2['arrival_time'])
      
      if time1 && time2
        time_diff = (time1 - time2).abs
        score += time_diff <= 30.minutes ? 1.0 : 0.5
        total_checks += 1
      end
    end
    
    # Compare airline
    if schedule1['airline'] && schedule2['airline']
      score += schedule1['airline'] == schedule2['airline'] ? 1.0 : 0.0
      total_checks += 1
    end
    
    # Compare flight number
    if schedule1['flight_number'] && schedule2['flight_number']
      score += schedule1['flight_number'] == schedule2['flight_number'] ? 1.0 : 0.0
      total_checks += 1
    end
    
    # Compare stops
    if schedule1['stops'] && schedule2['stops']
      score += schedule1['stops'] == schedule2['stops'] ? 1.0 : 0.0
      total_checks += 1
    end
    
    total_checks > 0 ? score / total_checks : 0.0
  end

  def compare_pricing(pricing1, pricing2)
    return 0.0 unless pricing1.is_a?(Hash) && pricing2.is_a?(Hash)
    
    score = 0.0
    total_checks = 0
    
    # Compare price (with tolerance for small differences)
    if pricing1['price'] && pricing2['price']
      price1 = pricing1['price'].to_f
      price2 = pricing2['price'].to_f
      
      if price1 > 0 && price2 > 0
        price_diff_percentage = (price1 - price2).abs / [price1, price2].max * 100
        score += price_diff_percentage <= 5 ? 1.0 : (price_diff_percentage <= 15 ? 0.5 : 0.0)
        total_checks += 1
      end
    end
    
    # Compare currency
    if pricing1['currency'] && pricing2['currency']
      score += pricing1['currency'] == pricing2['currency'] ? 1.0 : 0.0
      total_checks += 1
    end
    
    # Compare cabin class
    if pricing1['cabin_class'] && pricing2['cabin_class']
      score += pricing1['cabin_class'] == pricing2['cabin_class'] ? 1.0 : 0.0
      total_checks += 1
    end
    
    total_checks > 0 ? score / total_checks : 0.0
  end

  def parse_time(time_value)
    return nil if time_value.blank?
    
    begin
      Time.parse(time_value.to_s)
    rescue ArgumentError
      nil
    end
  end

  def merge_duplicate_group(group)
    return if group.count < 2
    
    @duplicates_found += group.count
    
    # Sort by data quality and timestamp
    sorted_group = group.sort_by { |r| [r.validation_status == 'valid' ? 0 : 1, r.data_timestamp] }
    
    # Keep the best record
    primary_record = sorted_group.first
    
    # Update other records to point to the primary
    secondary_records = sorted_group[1..-1]
    
    secondary_records.each do |record|
      begin
        record.update!(
          duplicate_group_id: primary_record.id,
          validation_status: 'invalid'
        )
        @merged_count += 1
      rescue => e
        @errors << "Failed to merge record #{record.id}: #{e.message}"
      end
    end
    
    # Update primary record with merged information
    update_primary_record(primary_record, secondary_records)
  end

  def update_primary_record(primary, secondary_records)
    # Merge additional information from secondary records
    merged_schedule = primary.schedule.dup
    merged_pricing = primary.pricing.dup
    
    secondary_records.each do |secondary|
      # Merge schedule information
      if secondary.schedule.is_a?(Hash)
        secondary.schedule.each do |key, value|
          if merged_schedule[key].blank? && value.present?
            merged_schedule[key] = value
          end
        end
      end
      
      # Merge pricing information
      if secondary.pricing.is_a?(Hash)
        secondary.pricing.each do |key, value|
          if merged_pricing[key].blank? && value.present?
            merged_pricing[key] = value
          end
        end
      end
    end
    
    # Update primary record
    primary.update!(
      schedule: merged_schedule,
      pricing: merged_pricing,
      data_timestamp: [primary.data_timestamp, *secondary_records.map(&:data_timestamp)].max
    )
  end

  def calculate_similarity_score(record1, record2)
    return 0.0 unless records_are_similar?(record1, record2)
    
    schedule_score = compare_schedules(record1.schedule, record2.schedule)
    pricing_score = compare_pricing(record1.pricing, record2.pricing)
    
    # Weighted average
    (schedule_score * 0.6) + (pricing_score * 0.4)
  end

  def determine_confidence_level(similarity_score)
    case similarity_score
    when 0.9..1.0
      'very_high'
    when 0.8...0.9
      'high'
    when 0.7...0.8
      'medium'
    when 0.6...0.7
      'low'
    else
      'very_low'
    end
  end
end
