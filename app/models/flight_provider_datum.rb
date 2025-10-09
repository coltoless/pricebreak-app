class FlightProviderDatum < ApplicationRecord
  # Validations
  validates :flight_identifier, presence: true, uniqueness: { scope: :provider }
  validates :provider, presence: true
  validates :route, presence: true
  validates :schedule, presence: true
  validates :pricing, presence: true
  validates :data_timestamp, presence: true
  validates :validation_status, inclusion: { in: %w[pending valid suspicious invalid] }

  # Scopes
  scope :by_provider, ->(provider) { where(provider: provider) }
  scope :by_route, ->(route) { where(route: route) }
  scope :by_status, ->(status) { where(validation_status: status) }
  scope :recent, -> { where('data_timestamp >= ?', 1.hour.ago) }
  scope :valid_data, -> { where(validation_status: 'valid') }
  scope :needs_validation, -> { where(validation_status: 'pending') }
  scope :by_duplicate_group, ->(group_id) { where(duplicate_group_id: group_id) }

  # Constants
  VALIDATION_STATUSES = %w[pending valid suspicious invalid].freeze
  PROVIDERS = %w[skyscanner amadeus google_flights kiwi expedia kayak].freeze

  # Callbacks
  before_validation :set_defaults
  before_save :normalize_data

  def self.find_duplicates(route, date, provider = nil)
    scope = where(route: route)
    scope = scope.by_provider(provider) if provider
    
    # Group by duplicate_group_id if available
    scope = scope.where.not(duplicate_group_id: nil)
    
    scope.group(:duplicate_group_id)
         .having('COUNT(*) > 1')
         .pluck(:duplicate_group_id)
  end

  def self.merge_duplicates(duplicate_group_id)
    duplicates = by_duplicate_group(duplicate_group_id).order(:data_timestamp)
    return if duplicates.count < 2
    
    # Keep the most recent valid record
    primary_record = duplicates.valid_data.last || duplicates.last
    
    # Update other records to point to the primary
    duplicates.where.not(id: primary_record.id).update_all(
      duplicate_group_id: primary_record.id,
      validation_status: 'invalid'
    )
    
    primary_record
  end

  def self.cleanup_old_data(hours_to_keep = 24)
    cutoff_time = Time.current - hours_to_keep.hours
    
    # Archive old data before deletion (optional)
    old_records = where('data_timestamp < ?', cutoff_time)
    
    # Delete old records
    deleted_count = old_records.delete_all
    
    Rails.logger.info "Cleaned up #{deleted_count} old flight provider data records older than #{hours_to_keep} hours"
    
    return deleted_count
  end

  def self.data_quality_summary(provider = nil, hours = 24)
    scope = where('data_timestamp >= ?', Time.current - hours.hours)
    scope = scope.by_provider(provider) if provider
    
    total_records = scope.count
    valid_records = scope.valid_data.count
    suspicious_records = scope.by_status('suspicious').count
    invalid_records = scope.by_status('invalid').count
    
    {
      total: total_records,
      valid: valid_records,
      suspicious: suspicious_records,
      invalid: invalid_records,
      quality_percentage: total_records > 0 ? (valid_records.to_f / total_records * 100).round(2) : 0
    }
  end

  def self.detect_data_anomalies(provider = nil, hours = 24)
    scope = where('data_timestamp >= ?', Time.current - hours.hours)
    scope = scope.by_provider(provider) if provider
    
    # Find records with unusual patterns
    anomalies = []
    
    # Check for pricing anomalies
    scope.valid_data.find_each do |record|
      pricing = record.pricing
      next unless pricing.is_a?(Hash)
      
      price = pricing['price'] || pricing[:price]
      next unless price.is_a?(Numeric)
      
      # Flag extremely low or high prices
      if price < 10 || price > 10000
        anomalies << {
          record_id: record.id,
          type: 'extreme_price',
          value: price,
          details: "Price #{price} seems unusual"
        }
      end
    end
    
    # Check for schedule anomalies
    scope.valid_data.find_each do |record|
      schedule = record.schedule
      next unless schedule.is_a?(Hash)
      
      departure = schedule['departure_time'] || schedule[:departure_time]
      arrival = schedule['arrival_time'] || schedule[:arrival_time]
      
      if departure && arrival
        begin
          dep_time = Time.parse(departure)
          arr_time = Time.parse(arrival)
          
          # Flag flights with very short or very long durations
          duration = (arr_time - dep_time) / 1.hour
          if duration < 0.5 || duration > 24
            anomalies << {
              record_id: record.id,
              type: 'unusual_duration',
              value: duration,
              details: "Flight duration #{duration.round(2)} hours seems unusual"
            }
          end
        rescue ArgumentError
          # Invalid time format
          anomalies << {
            record_id: record.id,
            type: 'invalid_time_format',
            value: "#{departure} - #{arrival}",
            details: "Invalid time format"
          }
        end
      end
    end
    
    anomalies
  end

  def mark_as_valid!
    update!(validation_status: 'valid')
  end

  def mark_as_suspicious!
    update!(validation_status: 'suspicious')
  end

  def mark_as_invalid!
    update!(validation_status: 'invalid')
  end

  def is_recent?
    data_timestamp >= 1.hour.ago
  end

  def is_stale?
    data_timestamp < 6.hours.ago
  end

  def extract_price
    return nil unless pricing.is_a?(Hash)
    
    pricing['price'] || pricing[:price] || pricing['amount'] || pricing[:amount]
  end

  def extract_departure_time
    return nil unless schedule.is_a?(Hash)
    
    schedule['departure_time'] || schedule[:departure_time] || schedule['departure'] || schedule[:departure]
  end

  def extract_arrival_time
    return nil unless schedule.is_a?(Hash)
    
    schedule['arrival_time'] || schedule[:arrival_time] || schedule['arrival'] || schedule[:arrival]
  end

  def extract_airline
    return nil unless schedule.is_a?(Hash)
    
    schedule['airline'] || schedule[:airline] || schedule['carrier'] || schedule[:carrier]
  end

  def extract_flight_number
    return nil unless schedule.is_a?(Hash)
    
    schedule['flight_number'] || schedule[:flight_number] || schedule['number'] || schedule[:number]
  end

  def extract_stops
    return nil unless schedule.is_a?(Hash)
    
    schedule['stops'] || schedule[:stops] || schedule['stop_count'] || schedule[:stop_count] || 0
  end

  def is_direct?
    extract_stops == 0
  end

  def has_layover?
    extract_stops > 0
  end

  def route_summary
    airline = extract_airline
    flight_num = extract_flight_number
    stops = extract_stops
    
    summary = "#{route}"
    summary += " via #{airline}" if airline
    summary += " #{flight_num}" if flight_num
    summary += " (#{stops} stop#{stops != 1 ? 's' : ''})" if stops
    
    summary
  end

  def price_summary
    price = extract_price
    return "Price not available" unless price
    
    currency = pricing['currency'] || pricing[:currency] || 'USD'
    "#{currency} #{price}"
  end

  def schedule_summary
    dep_time = extract_departure_time
    arr_time = extract_arrival_time
    
    return "Schedule not available" unless dep_time && arr_time
    
    begin
      dep = Time.parse(dep_time).strftime("%H:%M")
      arr = Time.parse(arr_time).strftime("%H:%M")
      "#{dep} → #{arr}"
    rescue ArgumentError
      "Invalid time format"
    end
  end

  def data_age
    Time.current - data_timestamp
  end

  def data_age_human
    age = data_age
    
    case
    when age < 1.minute
      "Just now"
    when age < 1.hour
      "#{(age / 1.minute).round} minutes ago"
    when age < 1.day
      "#{(age / 1.hour).round} hours ago"
    else
      "#{(age / 1.day).round} days ago"
    end
  end

  def update_duplicate_group
    # Find similar records and group them
    similar_records = FlightProviderDatum.where(route: route)
                                        .where(provider: provider)
                                        .where.not(id: id)
                                        .where('data_timestamp >= ?', 1.hour.ago)
    
    if similar_records.exists?
      # Use the first record's ID as the group ID
      group_id = similar_records.first.id
      update!(duplicate_group_id: group_id)
    else
      # Create a new group with this record
      update!(duplicate_group_id: id)
    end
  end

  private

  def set_defaults
    self.data_timestamp ||= Time.current
    self.validation_status ||= 'pending'
    self.schedule ||= {}
    self.pricing ||= {}
  end

  def normalize_data
    # Normalize route format
    normalize_route
    
    # Normalize schedule data
    normalize_schedule
    
    # Normalize pricing data
    normalize_pricing
  end

  def normalize_route
    return if route.blank?
    
    # Remove extra spaces and normalize separators
    self.route = route.strip.gsub(/\s+/, ' ').gsub(/\s*(?:to|→|-)\s*/, '-')
  end

  def normalize_schedule
    return unless schedule.is_a?(Hash)
    
    # Ensure all keys are strings
    self.schedule = schedule.transform_keys(&:to_s)
    
    # Normalize time formats
    ['departure_time', 'arrival_time', 'departure', 'arrival'].each do |time_key|
      if schedule[time_key].present?
        begin
          parsed_time = Time.parse(schedule[time_key])
          schedule[time_key] = parsed_time.iso8601
        rescue ArgumentError
          # Keep original if parsing fails
        end
      end
    end
  end

  def normalize_pricing
    return unless pricing.is_a?(Hash)
    
    # Ensure all keys are strings
    self.pricing = pricing.transform_keys(&:to_s)
    
    # Normalize price to decimal
    if pricing['price'].present?
      begin
        pricing['price'] = BigDecimal(pricing['price'].to_s)
      rescue ArgumentError
        pricing['price'] = nil
      end
    end
    
    # Normalize currency to uppercase
    if pricing['currency'].present?
      pricing['currency'] = pricing['currency'].to_s.upcase
    end
  end
end
