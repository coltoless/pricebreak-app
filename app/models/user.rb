class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations
  has_many :flight_filters, dependent: :destroy
  has_many :flight_alerts, dependent: :destroy
  has_many :price_alerts, dependent: :destroy
  has_many :launch_subscribers, dependent: :destroy

  # Validations
  validates :email, presence: true, uniqueness: true
  validates :firebase_uid, uniqueness: true, allow_nil: true

  # Scopes
  scope :with_active_filters, -> { joins(:flight_filters).where(flight_filters: { is_active: true }) }
  scope :with_active_alerts, -> { joins(:flight_alerts).where(flight_alerts: { status: 'active' }) }

  # Methods
  def has_active_filters?
    flight_filters.active.exists?
  end

  def has_active_alerts?
    flight_alerts.active.exists?
  end

  def active_filter_count
    flight_filters.active.count
  end

  def active_alert_count
    flight_alerts.active.count
  end

  def total_savings
    flight_alerts.where(status: 'triggered').sum(:price_drop_amount) || 0
  end

  def average_savings
    triggered_alerts = flight_alerts.where(status: 'triggered')
    return 0 if triggered_alerts.empty?
    
    triggered_alerts.average(:price_drop_amount).round(2) || 0
  end

  def filter_performance_summary
    total_filters = flight_filters.count
    active_filters = flight_filters.active.count
    triggered_alerts = flight_alerts.where(status: 'triggered').count
    
    {
      total_filters: total_filters,
      active_filters: active_filters,
      inactive_filters: total_filters - active_filters,
      triggered_alerts: triggered_alerts,
      success_rate: total_filters > 0 ? (triggered_alerts.to_f / total_filters * 100).round(2) : 0
    }
  end

  def can_create_more_filters?
    # Limit users to 10 active filters
    flight_filters.active.count < 10
  end

  def can_create_more_alerts?
    # Limit users to 20 active alerts
    flight_alerts.where(status: 'active').count < 20
  end

  def cleanup_old_data
    # Remove filters older than 1 year
    old_filters = flight_filters.where('created_at < ?', 1.year.ago)
    old_filters_count = old_filters.count
    old_filters.destroy_all
    
    # Remove alerts older than 6 months
    old_alerts = flight_alerts.where('created_at < ?', 6.months.ago)
    old_alerts_count = old_alerts.count
    old_alerts.destroy_all
    
    {
      filters_removed: old_filters_count,
      alerts_removed: old_alerts_count
    }
  end
end
