class FlightPriceHistory < ApplicationRecord
  # belongs_to :flight_filter, optional: true # Temporarily disabled

  # Validations
  validates :route, presence: true
  validates :date, presence: true
  validates :provider, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :booking_class, presence: true
  validates :timestamp, presence: true
  validates :data_quality_score, numericality: { greater_than: 0, less_than_or_equal_to: 1 }
  validates :price_validation_status, inclusion: { in: %w[valid suspicious invalid] }

  # Scopes
  scope :by_route, ->(route) { where(route: route) }
  scope :by_provider, ->(provider) { where(provider: provider) }
  scope :by_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :recent, -> { where('timestamp >= ?', 1.month.ago) }
  scope :valid_prices, -> { where(price_validation_status: 'valid') }
  scope :high_quality, -> { where('data_quality_score >= ?', 0.8) }
  scope :by_booking_class, ->(class_name) { where(booking_class: class_name) }

  # Constants
  VALIDATION_STATUSES = %w[valid suspicious invalid].freeze
  BOOKING_CLASSES = %w[economy premium-economy business first].freeze

  # Callbacks
  before_validation :set_defaults
  before_save :normalize_route

  def self.average_price_for_route(route, date_range = nil, provider = nil)
    scope = where(route: route)
    scope = scope.by_date_range(date_range.begin, date_range.end) if date_range
    scope = scope.by_provider(provider) if provider
    scope = scope.valid_prices.high_quality
    
    scope.average(:price)
  end

  def self.price_trend_for_route(route, days = 30)
    end_date = Date.current
    start_date = end_date - days.days
    
    prices = by_date_range(start_date, end_date)
              .by_route(route)
              .valid_prices
              .order(:date)
              .pluck(:date, :price)
    
    # Group by date and calculate average price per date
    prices_by_date = prices.group_by(&:first).transform_values { |vals| vals.map(&:last).sum.to_f / vals.length }
    
    # Return trend data
    prices_by_date.map { |date, avg_price| { date: date, average_price: avg_price } }
  end

  def self.lowest_price_for_route(route, date_range = nil)
    scope = where(route: route)
    scope = scope.by_date_range(date_range.begin, date_range.end) if date_range
    scope = scope.valid_prices.high_quality
    
    scope.minimum(:price)
  end

  def self.highest_price_for_route(route, date_range = nil)
    scope = where(route: route)
    scope = scope.by_date_range(date_range.begin, date_range.end) if date_range
    scope = scope.valid_prices.high_quality
    
    scope.maximum(:price)
  end

  def self.price_volatility_for_route(route, days = 30)
    end_date = Date.current
    start_date = end_date - days.days
    
    prices = by_date_range(start_date, end_date)
              .by_route(route)
              .valid_prices
              .high_quality
              .pluck(:price)
    
    return 0 if prices.length < 2
    
    # Calculate coefficient of variation (standard deviation / mean)
    mean = prices.sum.to_f / prices.length
    variance = prices.sum { |price| (price - mean) ** 2 } / prices.length
    standard_deviation = Math.sqrt(variance)
    
    (standard_deviation / mean * 100).round(2)
  end

  def self.detect_price_anomalies(route, threshold = 2.0)
    # Get recent prices for the route
    recent_prices = by_route(route)
                    .recent
                    .valid_prices
                    .pluck(:price)
    
    return [] if recent_prices.length < 5
    
    # Calculate statistics
    mean = recent_prices.sum.to_f / recent_prices.length
    variance = recent_prices.sum { |price| (price - mean) ** 2 } / recent_prices.length
    standard_deviation = Math.sqrt(variance)
    
    # Find anomalies (prices more than threshold standard deviations from mean)
    anomalies = recent_prices.select do |price|
      z_score = (price - mean).abs / standard_deviation
      z_score > threshold
    end
    
    anomalies
  end

  def self.cleanup_old_data(days_to_keep = 90)
    cutoff_date = Date.current - days_to_keep.days
    
    # Archive old data before deletion (optional)
    old_records = where('date < ?', cutoff_date)
    
    # Delete old records
    deleted_count = old_records.delete_all
    
    Rails.logger.info "Cleaned up #{deleted_count} old flight price history records older than #{days_to_keep} days"
    
    return deleted_count
  end

  def price_change_from_previous
    return nil unless previous_price
    
    change_amount = price - previous_price
    change_percentage = (change_amount / previous_price * 100).round(2)
    
    {
      amount: change_amount,
      percentage: change_percentage,
      direction: change_amount > 0 ? 'increase' : 'decrease'
    }
  end

  def previous_price
    FlightPriceHistory.where(route: route)
                     .where(provider: provider)
                     .where(booking_class: booking_class)
                     .where('date < ?', date)
                     .order(:date)
                     .last&.price
  end

  def next_price
    FlightPriceHistory.where(route: route)
                     .where(provider: provider)
                     .where(booking_class: booking_class)
                     .where('date > ?', date)
                     .order(:date)
                     .first&.price
  end

  def is_price_drop?
    return false unless previous_price
    price < previous_price
  end

  def is_price_increase?
    return false unless previous_price
    price > previous_price
  end

  def price_drop_amount
    return 0 unless previous_price && is_price_drop?
    previous_price - price
  end

  def price_drop_percentage
    return 0 unless previous_price && is_price_drop?
    ((previous_price - price) / previous_price * 100).round(2)
  end

  def is_significant_change?(threshold_percentage = 10)
    return false unless previous_price
    
    change_percentage = (price - previous_price).abs / previous_price * 100
    change_percentage >= threshold_percentage
  end

  def mark_as_suspicious!
    update!(price_validation_status: 'suspicious')
  end

  def mark_as_invalid!
    update!(price_validation_status: 'invalid')
  end

  def mark_as_valid!
    update!(price_validation_status: 'valid')
  end

  def update_quality_score
    score = 1.0
    
    # Reduce score for suspicious or invalid prices
    case price_validation_status
    when 'suspicious'
      score -= 0.3
    end
    
    # Reduce score for very old data
    if timestamp < 1.day.ago
      score -= 0.1
    elsif timestamp < 1.hour.ago
      score -= 0.05
    end
    
    # Ensure score stays within bounds
    score = [score, 0.1].max
    score = [score, 1.0].min
    
    update!(data_quality_score: score)
  end

  def route_summary
    "#{route} on #{date.strftime('%B %d, %Y')} via #{provider}"
  end

  private

  def set_defaults
    self.timestamp ||= Time.current
    self.data_quality_score ||= 1.0
    self.price_validation_status ||= 'valid'
  end

  def normalize_route
    # Ensure route format is consistent (e.g., "LAX-JFK" or "LAX to JFK")
    return if route.blank?
    
    # Remove extra spaces and normalize separators
    self.route = route.strip.gsub(/\s+/, ' ').gsub(/\s*(?:to|→|-)\s*/, '-')
  end
end
