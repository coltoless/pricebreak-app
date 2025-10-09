class AlertQualityUpdateJob < ApplicationJob
  queue_as :default

  # Retry on errors
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(alert_id = nil, timeframe = '30_days')
    if alert_id
      update_single_alert(alert_id, timeframe)
    else
      update_all_alerts(timeframe)
    end
  end

  # Update quality for a single alert
  def update_single_alert(alert_id, timeframe)
    alert = FlightAlert.find(alert_id)
    service = AlertQualityService.new(alert, timeframe: timeframe)
    
    old_score = alert.alert_quality_score || 0.0
    new_score = service.update_alert_quality
    
    Rails.logger.info "Updated quality for alert #{alert_id}: #{old_score} -> #{new_score}"
    
    # Send notification if quality improved significantly
    if new_score - old_score > 0.2
      notify_quality_improvement(alert, old_score, new_score)
    end
    
    { success: true, alert_id: alert_id, old_score: old_score, new_score: new_score }
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "Alert #{alert_id} not found for quality update"
    { success: false, error: "Alert not found" }
  rescue => e
    Rails.logger.error "Failed to update quality for alert #{alert_id}: #{e.message}"
    { success: false, error: e.message }
  end

  # Update quality for all alerts
  def update_all_alerts(timeframe)
    results = { updated: 0, errors: [], improvements: 0 }
    
    # Process alerts in batches to avoid memory issues
    FlightAlert.find_in_batches(batch_size: 100) do |alerts|
      alerts.each do |alert|
        begin
          service = AlertQualityService.new(alert, timeframe: timeframe)
          old_score = alert.alert_quality_score || 0.0
          new_score = service.update_alert_quality
          
          results[:updated] += 1
          
          if new_score - old_score > 0.1
            results[:improvements] += 1
            notify_quality_improvement(alert, old_score, new_score)
          end
        rescue => e
          results[:errors] << { alert_id: alert.id, error: e.message }
        end
      end
    end
    
    Rails.logger.info "Quality update completed: #{results[:updated]} updated, #{results[:improvements]} improved, #{results[:errors].count} errors"
    results
  end

  # Schedule quality updates for all alerts
  def self.schedule_quality_updates
    # Schedule immediate update for high-priority alerts
    high_priority_alerts = FlightAlert.where('alert_quality_score < ? OR alert_quality_score IS NULL', 0.5)
    high_priority_alerts.find_each do |alert|
      AlertQualityUpdateJob.perform_later(alert.id, '7_days')
    end
    
    # Schedule batch update for all alerts
    AlertQualityUpdateJob.perform_later(nil, '30_days')
    
    Rails.logger.info "Scheduled quality updates for #{high_priority_alerts.count} high-priority alerts and all alerts"
  end

  # Get quality update statistics
  def self.quality_update_stats
    recent_updates = FlightAlert.where('updated_at > ?', 24.hours.ago)
    
    {
      total_alerts: FlightAlert.count,
      updated_last_24h: recent_updates.count,
      average_quality_score: FlightAlert.average(:alert_quality_score) || 0,
      high_quality_alerts: FlightAlert.where('alert_quality_score >= ?', 0.8).count,
      low_quality_alerts: FlightAlert.where('alert_quality_score < ?', 0.5).count,
      alerts_needing_attention: FlightAlert.where('alert_quality_score < ? OR alert_quality_score IS NULL', 0.3).count
    }
  end

  private

  def notify_quality_improvement(alert, old_score, new_score)
    return unless alert.flight_filter&.user
    
    improvements = generate_improvement_details(alert, old_score, new_score)
    
    # Send email notification
    PriceAlertMailer.alert_quality_improvement(alert, improvements).deliver_later
    
    # Send push notification if enabled
    if alert.flight_filter&.notification_methods&.dig('push')
      send_quality_improvement_push(alert, improvements)
    end
    
    Rails.logger.info "Sent quality improvement notification for alert #{alert.id}"
  end

  def generate_improvement_details(alert, old_score, new_score)
    improvement_percentage = ((new_score - old_score) / old_score * 100).round(1) rescue 0
    
    {
      alert_id: alert.id,
      route: alert.route_description,
      old_score: old_score,
      new_score: new_score,
      improvement_percentage: improvement_percentage,
      quality_level: determine_quality_level(new_score),
      improvements: identify_specific_improvements(alert, old_score, new_score)
    }
  end

  def determine_quality_level(score)
    case score
    when 0.9..1.0 then 'excellent'
    when 0.8..0.9 then 'very_good'
    when 0.7..0.8 then 'good'
    when 0.6..0.7 then 'fair'
    when 0.5..0.6 then 'poor'
    else 'very_poor'
    end
  end

  def identify_specific_improvements(alert, old_score, new_score)
    improvements = []
    
    # Check if price accuracy improved
    if alert.current_price && alert.target_price
      price_accuracy = (alert.target_price - alert.current_price) / alert.target_price
      if price_accuracy > 0.1
        improvements << 'Better price accuracy'
      end
    end
    
    # Check if notification success improved
    if alert.notification_history.present?
      recent_success_rate = calculate_recent_success_rate(alert)
      if recent_success_rate > 0.8
        improvements << 'Improved notification delivery'
      end
    end
    
    # Check if data freshness improved
    if alert.last_checked && alert.last_checked > 1.day.ago
      improvements << 'More frequent data updates'
    end
    
    improvements
  end

  def calculate_recent_success_rate(alert)
    return 0 unless alert.notification_history.present?
    
    recent_notifications = alert.notification_history.last(5)
    return 0 if recent_notifications.empty?
    
    successful = recent_notifications.count { |n| n['success'] == true }
    successful.to_f / recent_notifications.count
  end

  def send_quality_improvement_push(alert, improvements)
    # Send push notification via ActionCable
    ActionCable.server.broadcast(
      "price_alerts_#{alert.flight_filter.user_id}",
      {
        type: 'quality_improvement',
        alert_id: alert.id,
        title: 'Alert Quality Improved!',
        body: "Your alert for #{alert.route_description} has improved to #{improvements[:quality_level].humanize} quality",
        data: {
          alert_id: alert.id,
          route: alert.route_description,
          old_score: improvements[:old_score],
          new_score: improvements[:new_score],
          improvement_percentage: improvements[:improvement_percentage]
        },
        timestamp: Time.current.iso8601
      }
    )
  end
end
