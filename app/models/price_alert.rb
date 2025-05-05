class PriceAlert < ApplicationRecord
  belongs_to :user
  has_one :auto_buy_setting, dependent: :destroy

  validates :target_price, presence: true, numericality: { greater_than: 0 }
  validates :notification_method, presence: true, inclusion: { in: %w[email push both] }
  validates :status, presence: true, inclusion: { in: %w[active triggered cancelled] }
  validates :max_price, numericality: { greater_than: 0 }, allow_nil: true
  validates :min_price, numericality: { greater_than: 0 }, allow_nil: true
  validate :price_range_validity

  scope :active, -> { where(status: 'active') }
  scope :for_user, ->(user) { where(user: user) }
  scope :with_auto_buy, -> { joins(:auto_buy_setting) }

  def check_price(current_price)
    return unless active?
    return unless price_matches_criteria?(current_price)

    if auto_buy_setting&.enabled?
      attempt_auto_buy(current_price)
    else
      trigger_alert(current_price)
    end
  end

  def cancel
    update(status: 'cancelled')
  end

  def price_matches_criteria?(current_price)
    return false if current_price > target_price
    return false if max_price && current_price > max_price
    return false if min_price && current_price < min_price
    true
  end

  private

  def price_range_validity
    return unless min_price && max_price
    errors.add(:max_price, "must be greater than min_price") if max_price <= min_price
  end

  def trigger_alert(current_price)
    update(status: 'triggered')

    case notification_method
    when 'email'
      send_email_notification(current_price)
    when 'push'
      send_push_notification(current_price)
    when 'both'
      send_email_notification(current_price)
      send_push_notification(current_price)
    end
  end

  def attempt_auto_buy(current_price)
    return unless auto_buy_setting&.payment_method_present?

    AutoBuyJob.perform_later(self, current_price)
  end

  def send_email_notification(current_price)
    PriceAlertMailer.price_alert_email(self, current_price).deliver_later
  end

  def send_push_notification(current_price)
    ActionCable.server.broadcast(
      "notifications_#{user.id}",
      {
        type: 'price_alert',
        message: "Price alert triggered! Current price: $#{current_price}",
        alert_id: id,
        current_price: current_price
      }
    )
  end
end 