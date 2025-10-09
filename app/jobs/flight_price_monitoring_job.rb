class FlightPriceMonitoringJob < ApplicationJob
  queue_as :monitoring

  # Retry on specific errors
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  retry_on Net::TimeoutError, wait: 30.seconds, attempts: 5
  retry_on Faraday::TimeoutError, wait: 30.seconds, attempts: 5

  # Discard on specific errors that won't be fixed by retrying
  discard_on ActiveRecord::RecordNotFound
  discard_on ArgumentError

  def perform(monitoring_type = :full)
    Rails.logger.info "Starting flight price monitoring job (#{monitoring_type})"
    
    start_time = Time.current
    monitoring_service = PriceMonitoringService.new
    
    case monitoring_type
    when :full
      result = monitoring_service.monitor_all_filters
    when :urgent_only
      result = monitor_urgent_filters_only(monitoring_service)
    when :specific_filter
      # This would be called with a specific filter_id
      result = { success: false, error: 'Specific filter monitoring not implemented yet' }
    else
      result = monitoring_service.monitor_all_filters
    end
    
    duration = Time.current - start_time
    
    # Log results
    log_monitoring_results(result, duration, monitoring_type)
    
    # Schedule next monitoring run
    schedule_next_monitoring_run(monitoring_type)
    
    # Update system health metrics
    update_system_health_metrics(result)
    
    result
  rescue => e
    Rails.logger.error "Flight price monitoring job failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    # Schedule retry with exponential backoff
    schedule_retry_monitoring(monitoring_type, e)
    
    { success: false, error: e.message }
  end

  private

  # Monitor only urgent filters (those with departure within 30 days)
  def monitor_urgent_filters_only(monitoring_service)
    urgent_filters = FlightFilter.active
                                .where('next_check_scheduled <= ?', Time.current)
                                .where('departure_dates::text LIKE ?', "%#{(Date.current + 30.days).strftime('%Y-%m-%d')}%")
    
    Rails.logger.info "Monitoring #{urgent_filters.count} urgent filters"
    
    result = { success: true, monitored_count: 0, alerts_triggered: 0, price_breaks_detected: 0, errors: [] }
    
    urgent_filters.find_each do |filter|
      begin
        monitoring_service.monitor_single_filter(filter)
        result[:monitored_count] += 1
      rescue => e
        error_msg = "Error monitoring urgent filter #{filter.id}: #{e.message}"
        result[:errors] << error_msg
        Rails.logger.error error_msg
      end
    end
    
    result
  end

  # Log monitoring results
  def log_monitoring_results(result, duration, monitoring_type)
    if result[:success]
      Rails.logger.info "Price monitoring completed successfully (#{monitoring_type})"
      Rails.logger.info "  Duration: #{duration.round(2)}s"
      Rails.logger.info "  Filters monitored: #{result[:monitored_count]}"
      Rails.logger.info "  Alerts triggered: #{result[:alerts_triggered]}"
      Rails.logger.info "  Price breaks detected: #{result[:price_breaks_detected]}"
      
      if result[:errors].any?
        Rails.logger.warn "  Errors encountered: #{result[:errors].count}"
        result[:errors].each { |error| Rails.logger.warn "    #{error}" }
      end
    else
      Rails.logger.error "Price monitoring failed (#{monitoring_type})"
      Rails.logger.error "  Duration: #{duration.round(2)}s"
      Rails.logger.error "  Errors: #{result[:errors].join(', ')}"
    end
  end

  # Schedule the next monitoring run
  def schedule_next_monitoring_run(monitoring_type)
    case monitoring_type
    when :full
      # Full monitoring every 2 hours
      next_run_time = 2.hours.from_now
    when :urgent_only
      # Urgent monitoring every 30 minutes
      next_run_time = 30.minutes.from_now
    else
      # Default to 1 hour
      next_run_time = 1.hour.from_now
    end
    
    # Add some randomization to prevent thundering herd
    jitter = rand(0.1..0.3) * (next_run_time - Time.current)
    next_run_time += jitter
    
    FlightPriceMonitoringJob.set(wait_until: next_run_time).perform_later(monitoring_type)
    
    Rails.logger.info "Next monitoring run scheduled for #{next_run_time}"
  end

  # Schedule retry with exponential backoff
  def schedule_retry_monitoring(monitoring_type, error)
    retry_count = (arguments[1] || 0) + 1
    
    if retry_count <= 3
      wait_time = 2 ** retry_count * 60.seconds # 2, 4, 8 minutes
      FlightPriceMonitoringJob.set(wait: wait_time).perform_later(monitoring_type, retry_count)
      Rails.logger.info "Scheduled retry #{retry_count} in #{wait_time} seconds"
    else
      Rails.logger.error "Max retries exceeded for monitoring job"
      # Could send alert to admin here
    end
  end

  # Update system health metrics
  def update_system_health_metrics(result)
    # Store monitoring metrics in Redis for dashboard
    metrics = {
      last_monitoring_run: Time.current.iso8601,
      success: result[:success],
      monitored_count: result[:monitored_count] || 0,
      alerts_triggered: result[:alerts_triggered] || 0,
      price_breaks_detected: result[:price_breaks_detected] || 0,
      error_count: result[:errors]&.count || 0,
      system_health: PriceMonitoringService.calculate_system_health,
      quality_metrics: get_quality_metrics
    }
    
    Rails.cache.write('monitoring_metrics', metrics, expires_in: 1.hour)
    
    # Schedule quality updates for triggered alerts
    if result[:alerts_triggered] > 0
      schedule_quality_updates
    end
  end

  # Class method to start monitoring
  def self.start_monitoring
    # Cancel any existing monitoring jobs
    FlightPriceMonitoringJob.where(queue_name: 'monitoring').destroy_all
    
    # Start full monitoring
    FlightPriceMonitoringJob.perform_later(:full)
    
    # Start urgent monitoring (runs more frequently)
    FlightPriceMonitoringJob.set(wait: 5.minutes).perform_later(:urgent_only)
    
    Rails.logger.info "Flight price monitoring started"
  end

  # Class method to stop monitoring
  def self.stop_monitoring
    FlightPriceMonitoringJob.where(queue_name: 'monitoring').destroy_all
    Rails.logger.info "Flight price monitoring stopped"
  end

  # Class method to get monitoring status
  def self.monitoring_status
    metrics = Rails.cache.read('monitoring_metrics') || {}
    
    {
      is_running: FlightPriceMonitoringJob.where(queue_name: 'monitoring').exists?,
      last_run: metrics[:last_monitoring_run],
      system_health: metrics[:system_health] || 'unknown',
      stats: PriceMonitoringService.monitoring_stats,
      quality_metrics: metrics[:quality_metrics] || {}
    }
  end

  private

  # Get quality metrics for monitoring dashboard
  def get_quality_metrics
    {
      average_quality_score: FlightAlert.average(:alert_quality_score) || 0,
      high_quality_alerts: FlightAlert.where('alert_quality_score >= ?', 0.8).count,
      low_quality_alerts: FlightAlert.where('alert_quality_score < ?', 0.5).count,
      alerts_needing_attention: FlightAlert.where('alert_quality_score < ? OR alert_quality_score IS NULL', 0.3).count,
      recent_quality_updates: FlightAlert.where('updated_at > ?', 1.hour.ago).count
    }
  end

  # Schedule quality updates for recently triggered alerts
  def schedule_quality_updates
    # Schedule immediate quality update for high-priority alerts
    high_priority_alerts = FlightAlert.where(status: 'triggered')
                                     .where('created_at > ?', 1.hour.ago)
                                     .where('alert_quality_score < ? OR alert_quality_score IS NULL', 0.7)
    
    high_priority_alerts.find_each do |alert|
      AlertQualityUpdateJob.perform_later(alert.id, '7_days')
    end
    
    # Schedule batch quality update for all alerts (less frequent)
    AlertQualityUpdateJob.perform_later(nil, '30_days') if rand < 0.1 # 10% chance per monitoring run
  end
end



