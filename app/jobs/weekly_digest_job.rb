class WeeklyDigestJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting weekly digest job"
    
    # Get all users with active alerts
    users_with_alerts = User.joins(:flight_filters)
                           .where(flight_filters: { status: 'active' })
                           .distinct
    
    users_with_alerts.find_each do |user|
      send_weekly_digest(user)
    end
    
    Rails.logger.info "Weekly digest job completed for #{users_with_alerts.count} users"
  end

  private

  def send_weekly_digest(user)
    # Get user's alerts and activity for the past week
    week_ago = 1.week.ago
    
    alerts = user.flight_alerts
                .where('created_at >= ?', week_ago)
                .includes(:flight_filter)
    
    # Calculate summary data
    summary_data = {
      total_savings: alerts.where(status: 'triggered').sum(:price_drop_amount),
      alerts_triggered: alerts.where(status: 'triggered').count,
      new_alerts_created: alerts.where('created_at >= ?', week_ago).count,
      top_deals: get_top_deals(alerts),
      quality_improvements: get_quality_improvements(user, week_ago),
      upcoming_trips: get_upcoming_trips(user)
    }
    
    # Only send digest if there's meaningful activity
    if summary_data[:alerts_triggered] > 0 || summary_data[:new_alerts_created] > 0
      PriceAlertMailer.weekly_summary(user, summary_data).deliver_later
    end
  end

  def get_top_deals(alerts)
    alerts.where(status: 'triggered')
          .order(:price_drop_amount)
          .limit(5)
          .map do |alert|
      {
        route: alert.route_description,
        savings: alert.price_drop_amount,
        percentage: alert.price_drop_percentage_calculated,
        current_price: alert.current_price,
        target_price: alert.target_price
      }
    end
  end

  def get_quality_improvements(user, since)
    # Find alerts with significant quality improvements
    user.flight_alerts
        .where('updated_at >= ?', since)
        .where('alert_quality_score > ?', 0.7)
        .count
  end

  def get_upcoming_trips(user)
    # Find alerts for trips in the next 30 days
    user.flight_alerts
        .where('departure_date BETWEEN ? AND ?', Date.current, 30.days.from_now)
        .where(status: 'active')
        .limit(5)
        .map do |alert|
      {
        route: alert.route_description,
        departure_date: alert.departure_date,
        target_price: alert.target_price,
        current_price: alert.current_price
      }
    end
  end
end
