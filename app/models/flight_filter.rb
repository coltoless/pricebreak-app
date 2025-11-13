class FlightFilter < ApplicationRecord
  belongs_to :user
  has_many :flight_alerts, dependent: :destroy
  has_many :flight_price_histories, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 3, maximum: 100 }
  validates :origin_airports, presence: true
  validates :destination_airports, presence: true
  validates :trip_type, presence: true, inclusion: { in: %w[one-way round-trip multi-city] }
  validates :departure_dates, presence: true
  validates :passenger_details, presence: true
  validates :price_parameters, presence: true
  validates :advanced_preferences, presence: true
  validates :alert_settings, presence: true
  validates :date_flexibility, numericality: { greater_than: 0, less_than_or_equal_to: 30 }, allow_nil: true

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :by_trip_type, ->(type) { where(trip_type: type) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }

  # JSON field validations and defaults
  before_validation :set_defaults
  before_validation :validate_json_fields

  # Trip type constants
  TRIP_TYPES = %w[one-way round-trip multi-city].freeze
  CABIN_CLASSES = %w[economy premium-economy business first].freeze
  MAX_STOPS_OPTIONS = %w[nonstop 1-stop 2+].freeze

  def origin_airports_array
    return [] if origin_airports.blank?
    origin_airports.is_a?(Array) ? origin_airports : JSON.parse(origin_airports)
  rescue JSON::ParserError
    []
  end

  def destination_airports_array
    return [] if destination_airports.blank?
    destination_airports.is_a?(Array) ? destination_airports : JSON.parse(destination_airports)
  rescue JSON::ParserError
    []
  end

  def departure_dates_array
    return [] if departure_dates.blank?
    departure_dates.is_a?(Array) ? departure_dates : JSON.parse(departure_dates)
  rescue JSON::ParserError
    []
  end

  def return_dates_array
    return [] if return_dates.blank?
    return_dates.is_a?(Array) ? return_dates : JSON.parse(return_dates)
  rescue JSON::ParserError
    []
  end

  def route_description
    origins = origin_airports_array.join(', ')
    destinations = destination_airports_array.join(', ')
    "#{origins} → #{destinations}"
  end

  def passenger_count
    details = passenger_details.is_a?(Hash) ? passenger_details : {}
    (details['adults'] || 0) + (details['children'] || 0) + (details['infants'] || 0)
  end

  def target_price
    price_parameters&.dig('target_price') || 0
  end

  def max_price
    price_parameters&.dig('max_price') || 10000
  end

  def min_price
    price_parameters&.dig('min_price') || 0
  end

  def cabin_class
    advanced_preferences&.dig('cabin_class') || 'economy'
  end

  def max_stops
    advanced_preferences&.dig('max_stops') || 'any'
  end

  def airline_preferences
    advanced_preferences&.dig('airline_preferences') || []
  end

  def monitor_frequency
    alert_settings&.dig('monitor_frequency') || 'daily'
  end

  def notification_methods
    alert_settings&.dig('notification_methods') || { 'email' => true }
  end

  def is_urgent?
    return false unless departure_dates_array.any?
    
    earliest_date = departure_dates_array.map { |d| Date.parse(d) }.min
    (earliest_date - Date.current).to_i <= 30 # Within 30 days
  end

  def should_monitor_frequently?
    is_urgent? || monitor_frequency == 'real-time'
  end

  def deactivate!
    update!(is_active: false)
  end

  def activate!
    update!(is_active: true)
  end

  def duplicate?
    FlightFilter.where(origin_airports: origin_airports)
               .where(destination_airports: destination_airports)
               .where(trip_type: trip_type)
               .where.not(id: id)
               .exists?
  end

  private

  def set_defaults
    self.passenger_details = { 'adults' => 1, 'children' => 0, 'infants' => 0 } if passenger_details.blank?
    self.price_parameters = { 'target_price' => 0, 'max_price' => 10000, 'min_price' => 0 } if price_parameters.blank?
    self.advanced_preferences = { 'cabin_class' => 'economy', 'max_stops' => 'any', 'airline_preferences' => [] } if advanced_preferences.blank?
    self.alert_settings = { 'monitor_frequency' => 'daily', 'notification_methods' => { 'email' => true } } if alert_settings.blank?
    self.is_active = true if is_active.nil?
    self.date_flexibility = 3 if date_flexibility.nil?
  end

  def validate_json_fields
    validate_passenger_details
    validate_price_parameters
    validate_advanced_preferences
    validate_alert_settings
  end

  def validate_passenger_details
    return if passenger_details.blank?
    
    details = passenger_details.is_a?(Hash) ? passenger_details : {}
    adults = details['adults'] || 0
    children = details['children'] || 0
    infants = details['infants'] || 0
    
    if adults < 1
      errors.add(:passenger_details, 'must have at least one adult')
    end
    
    if (adults + children + infants) > 9
      errors.add(:passenger_details, 'cannot exceed 9 passengers')
    end
  end

  def validate_price_parameters
    return if price_parameters.blank?
    
    params = price_parameters.is_a?(Hash) ? price_parameters : {}
    min_price = params['min_price'] || 0
    max_price = params['max_price'] || 10000
    target_price = params['target_price'] || 0
    
    if min_price >= max_price
      errors.add(:price_parameters, 'minimum price must be less than maximum price')
    end
    
    if target_price < min_price || target_price > max_price
      errors.add(:price_parameters, 'target price must be within min/max range')
    end
  end

  def validate_advanced_preferences
    return if advanced_preferences.blank?
    
    prefs = advanced_preferences.is_a?(Hash) ? advanced_preferences : {}
    
    if prefs['cabin_class'] && !CABIN_CLASSES.include?(prefs['cabin_class'])
      errors.add(:advanced_preferences, 'invalid cabin class')
    end
    
    if prefs['max_stops'] && !MAX_STOPS_OPTIONS.include?(prefs['max_stops'])
      errors.add(:advanced_preferences, 'invalid max stops option')
    end
  end

  def validate_alert_settings
    return if alert_settings.blank?
    
    settings = alert_settings.is_a?(Hash) ? alert_settings : {}
    
    if settings['monitor_frequency'] && !%w[real-time hourly daily weekly].include?(settings['monitor_frequency'])
      errors.add(:alert_settings, 'invalid monitor frequency')
    end
    
    if settings['notification_methods']
      methods = settings['notification_methods'].is_a?(Hash) ? settings['notification_methods'] : {}
      if !methods.values.any? { |enabled| enabled == true }
        errors.add(:alert_settings, 'at least one notification method must be enabled')
      end
    end
  end
end
