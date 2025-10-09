class ScheduledQualityUpdateJob < ApplicationJob
  queue_as :default

  # Run this job every 6 hours
  def perform
    Rails.logger.info "Starting scheduled quality update job"
    
    # Update quality for all alerts
    AlertQualityUpdateJob.schedule_quality_updates
    
    # Send digest notifications for minor alerts
    send_digest_notifications
    
    # Clean up old notification history
    cleanup_old_notifications
    
    Rails.logger.info "Scheduled quality update job completed"
  end

  private

  # Send digest notifications for users with multiple minor alerts
  def send_digest_notifications
    # Find users with multiple minor alerts from the last 24 hours
    users_with_minor_alerts = FlightAlert.joins(:flight_filter)
                                        .where(status: 'triggered')
                                        .where('created_at > ?', 24.hours.ago)
                                        .where('alert_quality_score < ?', 0.8)
                                        .group('flight_filters.user_id')
                                        .having('COUNT(*) >= 3')
                                        .pluck('flight_filters.user_id')
    
    users_with_minor_alerts.each do |user_id|
      user = User.find(user_id)
      minor_alerts = user.flight_alerts
                        .where(status: 'triggered')
                        .where('created_at > ?', 24.hours.ago)
                        .where('alert_quality_score < ?', 0.8)
      
      # Send digest email
      PriceAlertMailer.price_digest(user, minor_alerts).deliver_later
    end
    
    Rails.logger.info "Sent digest notifications to #{users_with_minor_alerts.count} users"
  end

  # Clean up old notification history to prevent database bloat
  def cleanup_old_notifications
    # Remove notification history older than 90 days
    old_alerts = FlightAlert.where('created_at < ?', 90.days.ago)
    
    old_alerts.find_each do |alert|
      if alert.notification_history.present?
        # Keep only last 10 notifications
        alert.notification_history = alert.notification_history.last(10)
        alert.save!
      end
    end
    
    Rails.logger.info "Cleaned up notification history for #{old_alerts.count} old alerts"
  end
end
