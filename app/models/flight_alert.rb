class FlightAlert < ApplicationRecord
  belongs_to :user
  belongs_to :flight_filter, optional: true

  validates :origin, presence: true
  validates :destination, presence: true
  validates :departure_date, presence: true
  validates :target_price, presence: true, numericality: { greater_than: 0 }
  validates :notification_method, inclusion: { in: %w[email push sms] }
  validates :alert_status, inclusion: { in: %w[active paused triggered expired] }
  validates :price_drop_percentage, numericality: { greater_than: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :alert_quality_score, numericality: { greater_than: 0, less_than_or_equal_to: 1 }, allow_nil: true

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :wedding_mode, -> { where(wedding_mode: true) }
  scope :expired, -> { where('departure_date < ?', Date.current) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :needs_checking, -> { where('next_check_scheduled <= ?', Time.current) }
  scope :high_priority, -> { where('alert_quality_score >= ?', 0.8) }

  # JSON field defaults
  before_validation :set_defaults
  before_validation :validate_json_fields

  # Status constants
  STATUSES = %w[active paused triggered expired].freeze
  NOTIFICATION_METHODS = %w[email push sms].freeze

  def self.create_for_wedding(user, wedding_date, destination, guest_count, target_price)
    create!(
      user: user,
      origin: 'US', # Default origin, can be made configurable
      destination: destination,
      departure_date: wedding_date - 2.days, # Arrive 2 days before wedding
      return_date: wedding_date + 2.days, # Leave 2 days after wedding
      passengers: guest_count,
      cabin_class: 'economy',
      target_price: target_price,
      notification_method: 'email',
      wedding_mode: true,
      wedding_date: wedding_date,
      guest_count: guest_count,
      status: 'active'
    )
  end

  def price_dropped?(current_price)
    current_price <= target_price
  end

  def should_trigger_auto_buy?(current_price)
    price_dropped?(current_price) && auto_buy_enabled?
  end

  def auto_buy_enabled?
    # Add auto-buy settings when implemented
    false
  end

  def route_description
    "#{origin} → #{destination}"
  end

  def wedding_description
    return nil unless wedding_mode?
    "Wedding on #{wedding_date.strftime('%B %d, %Y')} - #{guest_count} guests"
  end

  def price_drop_amount
    return 0 unless current_price && target_price
    target_price - current_price
  end

  def price_drop_percentage_calculated
    return 0 unless current_price && target_price
    ((target_price - current_price) / target_price * 100).round(2)
  end

  def savings_amount
    price_drop_amount
  end

  def is_urgent?
    return false unless departure_date
    (departure_date - Date.current).to_i <= 30 # Within 30 days
  end

  def should_check_frequently?
    is_urgent? || status == 'triggered'
  end

  def next_check_interval
    case
    when is_urgent?
      1.hour
    when status == 'triggered'
      30.minutes
    else
      6.hours
    end
  end

  def schedule_next_check
    update!(next_check_scheduled: Time.current + next_check_interval)
  end

  def trigger_alert!(current_price, provider = nil)
    self.current_price = current_price
    self.price_drop_percentage = price_drop_percentage_calculated
    self.status = 'triggered'
    self.last_checked = Time.current
    
    # Add to alert triggers
    self.alert_triggers ||= []
    self.alert_triggers << {
      timestamp: Time.current,
      price: current_price,
      provider: provider,
      drop_amount: price_drop_amount,
      drop_percentage: price_drop_percentage_calculated
    }
    
    save!
  end

  def pause!
    update!(status: 'paused')
  end

  def resume!
    update!(status: 'active')
  end

  def expire!
    update!(status: 'expired')
  end

  def add_notification_record(method, content, success)
    self.notification_history ||= []
    self.notification_history << {
      timestamp: Time.current,
      method: method,
      content: content,
      success: success
    }
    save!
  end

  def add_booking_action(action, details)
    self.booking_actions ||= []
    self.booking_actions << {
      timestamp: Time.current,
      action: action,
      details: details
    }
    save!
  end

  def update_quality_score
    # Calculate quality score based on various factors
    score = 1.0
    
    # Reduce score for alerts that haven't been triggered
    if status == 'active' && last_checked && last_checked < 1.week.ago
      score -= 0.2
    end
    
    # Increase score for alerts that have been triggered
    if status == 'triggered'
      score += 0.1
    end
    
    # Reduce score for alerts with many failed notifications
    if notification_history
      failed_count = notification_history.count { |n| n['success'] == false }
      score -= (failed_count * 0.05)
    end
    
    # Ensure score stays within bounds
    score = [score, 0.1].max
    score = [score, 1.0].min
    
    update!(alert_quality_score: score)
  end

  private

  def set_defaults
    self.status ||= 'active'
    self.alert_triggers ||= []
    self.notification_history ||= []
    self.booking_actions ||= []
    self.alert_quality_score ||= 1.0
    self.last_checked ||= Time.current
    self.next_check_scheduled ||= Time.current + 6.hours
  end

  def validate_json_fields
    validate_alert_triggers
    validate_notification_history
    validate_booking_actions
  end

  def validate_alert_triggers
    return if alert_triggers.blank?
    
    unless alert_triggers.is_a?(Array)
      errors.add(:alert_triggers, 'must be an array')
      return
    end
    
    alert_triggers.each_with_index do |trigger, index|
      unless trigger.is_a?(Hash) && trigger['timestamp'] && trigger['price']
        errors.add(:alert_triggers, "trigger at index #{index} is invalid")
      end
    end
  end

  def validate_notification_history
    return if notification_history.blank?
    
    unless notification_history.is_a?(Array)
      errors.add(:notification_history, 'must be an array')
      return
    end
    
    notification_history.each_with_index do |notification, index|
      unless notification.is_a?(Hash) && notification['timestamp'] && notification['method']
        errors.add(:notification_history, "notification at index #{index} is invalid")
      end
    end
  end

  def validate_booking_actions
    return if booking_actions.blank?
    
    unless booking_actions.is_a?(Array)
      errors.add(:booking_actions, 'must be an array')
      return
    end
    
    booking_actions.each_with_index do |action, index|
      unless action.is_a?(Hash) && action['timestamp'] && action['action']
        errors.add(:booking_actions, "action at index #{index} is invalid")
      end
    end
  end
end 