class AutoBuySetting < ApplicationRecord
  belongs_to :price_alert
  belongs_to :user

  validates :enabled, inclusion: { in: [true, false] }
  validates :max_attempts, numericality: { greater_than: 0, less_than_or_equal_to: 5 }
  validates :payment_method_type, presence: true, inclusion: { in: %w[credit_card paypal] }
  validates :payment_method_id, presence: true
  validates :billing_address, presence: true

  attr_encrypted :payment_method_id, key: Rails.application.credentials.secret_key_base[0..31]
  attr_encrypted :billing_address, key: Rails.application.credentials.secret_key_base[0..31]

  def payment_method_present?
    payment_method_id.present? && billing_address.present?
  end

  def increment_attempts!
    increment!(:attempts_count)
  end

  def max_attempts_reached?
    attempts_count >= max_attempts
  end
end 