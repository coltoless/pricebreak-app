class FlightAlert < ApplicationRecord
  belongs_to :user

  validates :origin, presence: true
  validates :destination, presence: true
  validates :departure_date, presence: true
  validates :target_price, presence: true, numericality: { greater_than: 0 }
  validates :notification_method, inclusion: { in: %w[email push sms] }

  scope :active, -> { where(status: 'active') }
  scope :wedding_mode, -> { where(wedding_mode: true) }
  scope :expired, -> { where('departure_date < ?', Date.current) }

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
end 