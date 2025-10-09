class MonitoringController < ApplicationController
  before_action :authenticate_user!, except: [:status, :health]
  before_action :set_admin_only, except: [:status, :health]

  # Public health check endpoint
  def health
    health_status = {
      status: 'ok',
      timestamp: Time.current.iso8601,
      version: Rails.application.class.module_parent_name::VERSION,
      environment: Rails.env,
      database: database_health,
      redis: redis_health,
      sidekiq: sidekiq_health,
      monitoring: monitoring_health
    }
    
    render json: health_status
  end

  # Public status endpoint
  def status
    status_info = {
      monitoring_active: monitoring_active?,
      last_check: last_monitoring_check,
      system_health: system_health_status,
      active_filters: FlightFilter.active.count,
      total_alerts: FlightAlert.count,
      recent_price_checks: recent_price_checks_count
    }
    
    render json: status_info
  end

  # Admin dashboard
  def dashboard
    @monitoring_stats = PriceMonitoringService.monitoring_stats
    @analysis_stats = PriceTrendAnalysisJob.analysis_status
    @cleanup_stats = FlightDataCleanupJob.cleanup_status
    @data_quality = FlightDataCleanupJob.data_quality_metrics
    @recent_alerts = FlightAlert.includes(:flight_filter)
                               .order(created_at: :desc)
                               .limit(20)
    @recent_errors = recent_errors
    @alert_quality_stats = AlertQualityService.quality_update_stats
    @notification_stats = NotificationService.delivery_stats
  end

  # Start monitoring
  def start_monitoring
    begin
      FlightPriceMonitoringJob.start_monitoring
      PriceTrendAnalysisJob.start_analysis
      FlightDataCleanupJob.start_cleanup
      
      redirect_to monitoring_dashboard_path, notice: 'Monitoring system started successfully'
    rescue => e
      redirect_to monitoring_dashboard_path, alert: "Failed to start monitoring: #{e.message}"
    end
  end

  # Stop monitoring
  def stop_monitoring
    begin
      FlightPriceMonitoringJob.stop_monitoring
      PriceTrendAnalysisJob.stop_monitoring
      FlightDataCleanupJob.stop_monitoring
      
      redirect_to monitoring_dashboard_path, notice: 'Monitoring system stopped successfully'
    rescue => e
      redirect_to monitoring_dashboard_path, alert: "Failed to stop monitoring: #{e.message}"
    end
  end

  # Restart monitoring
  def restart_monitoring
    begin
      stop_monitoring
      sleep(2) # Brief pause
      start_monitoring
      
      redirect_to monitoring_dashboard_path, notice: 'Monitoring system restarted successfully'
    rescue => e
      redirect_to monitoring_dashboard_path, alert: "Failed to restart monitoring: #{e.message}"
    end
  end

  # Manual price check for specific filter
  def check_filter
    @filter = FlightFilter.find(params[:filter_id])
    
    begin
      monitoring_service = PriceMonitoringService.new
      result = monitoring_service.monitor_single_filter(@filter)
      
      if result
        redirect_to flight_filter_path(@filter), notice: 'Price check completed successfully'
      else
        redirect_to flight_filter_path(@filter), alert: 'Price check failed'
      end
    rescue => e
      redirect_to flight_filter_path(@filter), alert: "Price check failed: #{e.message}"
    end
  end

  # Trigger manual analysis
  def trigger_analysis
    begin
      analysis_type = params[:analysis_type] || :full
      PriceTrendAnalysisJob.perform_later(analysis_type)
      
      redirect_to monitoring_dashboard_path, notice: "Analysis triggered: #{analysis_type}"
    rescue => e
      redirect_to monitoring_dashboard_path, alert: "Failed to trigger analysis: #{e.message}"
    end
  end

  # Trigger manual cleanup
  def trigger_cleanup
    begin
      cleanup_type = params[:cleanup_type] || :full
      FlightDataCleanupJob.perform_later(cleanup_type)
      
      redirect_to monitoring_dashboard_path, notice: "Cleanup triggered: #{cleanup_type}"
    rescue => e
      redirect_to monitoring_dashboard_path, alert: "Failed to trigger cleanup: #{e.message}"
    end
  end

  # Trigger quality updates
  def trigger_quality_update
    begin
      update_type = params[:update_type] || :all
      
      case update_type
      when 'all'
        AlertQualityUpdateJob.perform_later(nil, '30_days')
      when 'high_priority'
        AlertQualityUpdateJob.schedule_quality_updates
      when 'specific'
        alert_id = params[:alert_id]
        AlertQualityUpdateJob.perform_later(alert_id, '7_days')
      end
      
      redirect_to monitoring_dashboard_path, notice: "Quality update triggered: #{update_type}"
    rescue => e
      redirect_to monitoring_dashboard_path, alert: "Failed to trigger quality update: #{e.message}"
    end
  end

  # Send test notification
  def send_test_notification
    begin
      alert_id = params[:alert_id]
      alert = FlightAlert.find(alert_id)
      
      # Send test notification
      AlertDeliveryJob.perform_later(alert.id, :all, { test: true })
      
      redirect_to monitoring_dashboard_path, notice: "Test notification sent for alert #{alert_id}"
    rescue => e
      redirect_to monitoring_dashboard_path, alert: "Failed to send test notification: #{e.message}"
    end
  end

  # Get monitoring metrics (AJAX)
  def metrics
    metrics = {
      monitoring: PriceMonitoringService.monitoring_stats,
      analysis: PriceTrendAnalysisJob.analysis_status,
      cleanup: FlightDataCleanupJob.cleanup_status,
      data_quality: FlightDataCleanupJob.data_quality_metrics,
      system_health: system_health_status,
      alert_quality: AlertQualityService.quality_update_stats,
      notification_delivery: NotificationService.delivery_stats,
      smart_alerts: get_smart_alert_metrics,
      timestamp: Time.current.iso8601
    }
    
    render json: metrics
  end

  # Get recent alerts (AJAX)
  def recent_alerts
    alerts = FlightAlert.includes(:flight_filter)
                       .order(created_at: :desc)
                       .limit(params[:limit] || 10)
    
    render json: alerts.map do |alert|
      {
        id: alert.id,
        route: alert.route_description,
        current_price: alert.current_price,
        target_price: alert.target_price,
        savings: alert.savings_amount,
        status: alert.status,
        created_at: alert.created_at.iso8601,
        filter_name: alert.flight_filter&.name
      }
    end
  end

  # Get system logs (AJAX)
  def logs
    log_type = params[:log_type] || 'monitoring'
    limit = params[:limit] || 50
    
    # This would typically read from log files or a log aggregation service
    logs = get_system_logs(log_type, limit)
    
    render json: { logs: logs, log_type: log_type, count: logs.length }
  end

  private

  def set_admin_only
    # Add admin check here - for now, just check if user is authenticated
    unless current_user&.admin?
      redirect_to root_path, alert: 'Access denied'
    end
  end

  def database_health
    begin
      ActiveRecord::Base.connection.execute('SELECT 1')
      { status: 'ok', response_time: measure_response_time { ActiveRecord::Base.connection.execute('SELECT 1') } }
    rescue => e
      { status: 'error', error: e.message }
    end
  end

  def redis_health
    begin
      Rails.cache.write('health_check', Time.current.to_i, expires_in: 1.minute)
      Rails.cache.read('health_check')
      { status: 'ok', response_time: measure_response_time { Rails.cache.read('health_check') } }
    rescue => e
      { status: 'error', error: e.message }
    end
  end

  def sidekiq_health
    begin
      # Check if Sidekiq is running
      stats = Sidekiq::Stats.new
      {
        status: 'ok',
        processed: stats.processed,
        failed: stats.failed,
        enqueued: stats.enqueued,
        queues: stats.queues
      }
    rescue => e
      { status: 'error', error: e.message }
    end
  end

  def monitoring_health
    begin
      metrics = Rails.cache.read('monitoring_metrics') || {}
      {
        status: 'ok',
        last_run: metrics[:last_monitoring_run],
        system_health: metrics[:system_health] || 'unknown',
        monitored_count: metrics[:monitored_count] || 0,
        alerts_triggered: metrics[:alerts_triggered] || 0
      }
    rescue => e
      { status: 'error', error: e.message }
    end
  end

  def monitoring_active?
    FlightPriceMonitoringJob.where(queue_name: 'monitoring').exists?
  end

  def last_monitoring_check
    FlightFilter.maximum(:last_checked)
  end

  def system_health_status
    PriceMonitoringService.calculate_system_health
  end

  def recent_price_checks_count
    FlightPriceHistory.where('timestamp >= ?', 1.hour.ago).count
  end

  def recent_errors
    # This would typically come from a log aggregation service
    # For now, return empty array
    []
  end

  def get_system_logs(log_type, limit)
    # This would typically read from log files or a log aggregation service
    # For now, return mock data
    case log_type
    when 'monitoring'
      [
        { timestamp: Time.current.iso8601, level: 'INFO', message: 'Price monitoring completed successfully' },
        { timestamp: 1.minute.ago.iso8601, level: 'INFO', message: 'Monitoring 15 filters' },
        { timestamp: 2.minutes.ago.iso8601, level: 'WARN', message: 'No prices found for filter 123' }
      ]
    when 'analysis'
      [
        { timestamp: Time.current.iso8601, level: 'INFO', message: 'Trend analysis completed' },
        { timestamp: 5.minutes.ago.iso8601, level: 'INFO', message: 'Analyzed 25 routes' }
      ]
    when 'cleanup'
      [
        { timestamp: Time.current.iso8601, level: 'INFO', message: 'Data cleanup completed' },
        { timestamp: 10.minutes.ago.iso8601, level: 'INFO', message: 'Removed 150 old records' }
      ]
    else
      []
    end
  end

  def measure_response_time
    start_time = Time.current
    yield
    ((Time.current - start_time) * 1000).round(2) # Convert to milliseconds
  end

  def get_smart_alert_metrics
    {
      total_alerts: FlightAlert.count,
      triggered_alerts: FlightAlert.where(status: 'triggered').count,
      active_alerts: FlightAlert.where(status: 'active').count,
      average_quality_score: FlightAlert.average(:alert_quality_score) || 0,
      high_quality_alerts: FlightAlert.where('alert_quality_score >= ?', 0.8).count,
      low_quality_alerts: FlightAlert.where('alert_quality_score < ?', 0.5).count,
      recent_notifications: FlightAlert.where('created_at >= ?', 24.hours.ago)
                                     .where.not(notification_history: nil)
                                     .count,
      spam_prevention_active: FlightAlert.where('created_at >= ?', 1.hour.ago)
                                        .where("notification_history::text LIKE '%spam%'")
                                        .count,
      intelligence_filtered: FlightAlert.where('created_at >= ?', 24.hours.ago)
                                       .where(status: 'active')
                                       .where('alert_quality_score < ?', 0.3)
                                       .count
    }
  end
end



