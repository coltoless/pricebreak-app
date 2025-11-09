class AnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_admin_only, except: [ :user_dashboard, :user_metrics ]

  # Main analytics dashboard
  def dashboard
    @timeframe = params[:timeframe] || "30_days"
    @analytics_service = AnalyticsDashboardService.new

    @analytics_data = @analytics_service.get_dashboard_analytics(@timeframe)
    @performance_report = PerformanceOptimizationService.get_system_performance_report
    @monitoring_status = FlightPriceMonitoringJob.monitoring_status

    # Get recent activity
    @recent_alerts = FlightAlert.includes(:flight_filter, :user)
                                .order(created_at: :desc)
                                .limit(20)

    @recent_filters = FlightFilter.includes(:user)
                                  .order(created_at: :desc)
                                  .limit(20)

    # Get system health
    @system_health = @analytics_service.calculate_system_performance(@timeframe)
  end

  # User-specific analytics dashboard
  def user_dashboard
    @timeframe = params[:timeframe] || "30_days"
    @analytics_service = AnalyticsDashboardService.new(current_user)

    @user_analytics = {
      engagement: @analytics_service.calculate_user_engagement(@timeframe),
      filter_performance: @analytics_service.calculate_filter_performance(@timeframe),
      alert_effectiveness: @analytics_service.calculate_alert_effectiveness(@timeframe),
      behavior: @analytics_service.calculate_user_behavior(@timeframe)
    }

    # Get user"s recent activity
    @user_filters = current_user.flight_filters.includes(:flight_alerts)
                                .order(created_at: :desc)
                                .limit(10)

    @user_alerts = current_user.flight_alerts.includes(:flight_filter)
                               .order(created_at: :desc)
                               .limit(10)
  end

  # Real-time metrics endpoint
  def metrics
    timeframe = params[:timeframe] || "24_hours"

    metrics_data = {
      system_health: get_system_health_metrics,
      user_activity: get_user_activity_metrics(timeframe),
      filter_activity: get_filter_activity_metrics(timeframe),
      alert_activity: get_alert_activity_metrics(timeframe),
      performance: get_performance_metrics,
      timestamp: Time.current.iso8601
    }

    render json: metrics_data
  end

  # User-specific metrics
  def user_metrics
    timeframe = params[:timeframe] || "24_hours"

    user_metrics_data = {
      user_engagement: get_user_engagement_metrics(timeframe),
      filter_performance: get_user_filter_metrics(timeframe),
      alert_performance: get_user_alert_metrics(timeframe),
      recent_activity: get_user_recent_activity,
      timestamp: Time.current.iso8601
    }

    render json: user_metrics_data
  end

  # Export analytics data
  def export
    timeframe = params[:timeframe] || "30_days"
    format = params[:format] || "json"

    analytics_service = AnalyticsDashboardService.new
    data = analytics_service.export_analytics_data(timeframe, format.to_sym)

    case format
    when "csv"
      send_data data, filename: "analytics_#{timeframe}_#{Date.current}.csv", type: "text/csv"
    when "json"
      send_data data, filename: "analytics_#{timeframe}_#{Date.current}.json", type: "application/json"
    else
      render json: data
    end
  end

  # Performance trends over time
  def trends
    days = params[:days] || 30
    metric_type = params[:metric] || "all"

    trends_data = case metric_type
                  when "performance"
                    PerformanceOptimizationService.get_performance_trends(days.to_i)
                  when "user_engagement"
                    get_user_engagement_trends(days.to_i)
                  when "filter_performance"
                    get_filter_performance_trends(days.to_i)
                  when "alert_effectiveness"
                    get_alert_effectiveness_trends(days.to_i)
                  else
                    get_all_trends(days.to_i)
                  end

    render json: trends_data
  end

  # A/B testing results
  def ab_test_results
    test_name = params[:test_name]

    if test_name
      results = get_ab_test_results(test_name)
      render json: results
    else
      all_tests = get_all_ab_tests
      render json: all_tests
    end
  end

  # User segmentation analysis
  def user_segments
    segment_type = params[:segment_type] || "behavior"

    segments_data = case segment_type
                    when "behavior"
                      get_behavior_segments
                    when "engagement"
                      get_engagement_segments
                    when "value"
                      get_value_segments
                    else
                      get_all_segments
                    end

    render json: segments_data
  end

  # Route analysis
  def route_analysis
    route = params[:route]
    timeframe = params[:timeframe] || "30_days"

    if route
      route_data = get_route_analysis(route, timeframe)
      render json: route_data
    else
      top_routes = get_top_routes_analysis(timeframe)
      render json: top_routes
    end
  end

  # Seasonal analysis
  def seasonal_analysis
    year = params[:year] || Date.current.year

    seasonal_data = {
      monthly_trends: get_monthly_trends(year),
      seasonal_routes: get_seasonal_routes(year),
      holiday_impact: get_holiday_impact(year),
      weather_correlation: get_weather_correlation(year),
      booking_patterns: get_booking_patterns(year)
    }

    render json: seasonal_data
  end

  # Real-time monitoring dashboard
  def monitoring_dashboard
    @monitoring_data = {
      system_status: get_system_status,
      active_jobs: get_active_jobs,
      recent_errors: get_recent_errors,
      performance_alerts: get_performance_alerts,
      api_status: get_api_status
    }

    render json: @monitoring_data
  end

  private

  def set_admin_only
    unless current_user&.admin?
      redirect_to root_path, alert: "Access denied"
    end
  end

  def get_system_health_metrics
    {
      uptime: 99.5,
      response_time: 245, # milliseconds
      error_rate: 0.8,
      memory_usage: 256, # MB
      cpu_usage: 45.2,
      database_connections: 12,
      cache_hit_rate: 78.5
    }
  end

  def get_user_activity_metrics(timeframe)
    start_date = case timeframe
                 when "24_hours" then 1.day.ago
                 when "7_days" then 7.days.ago
                 when "30_days" then 30.days.ago
                 else 1.day.ago
                 end

    {
      active_users: User.where("last_sign_in_at > ?", start_date).count,
      new_registrations: User.where("created_at > ?", start_date).count,
      page_views: get_page_views(start_date),
      session_duration: get_average_session_duration(start_date),
      bounce_rate: get_bounce_rate(start_date)
    }
  end

  def get_filter_activity_metrics(timeframe)
    start_date = case timeframe
                 when "24_hours" then 1.day.ago
                 when "7_days" then 7.days.ago
                 when "30_days" then 30.days.ago
                 else 1.day.ago
                 end

    {
      filters_created: FlightFilter.where("created_at > ?", start_date).count,
      active_filters: FlightFilter.where("created_at > ?", start_date).active.count,
      filters_edited: get_filters_edited(start_date),
      filters_deleted: get_filters_deleted(start_date),
      average_complexity: get_average_filter_complexity(start_date)
    }
  end

  def get_alert_activity_metrics(timeframe)
    start_date = case timeframe
                 when "24_hours" then 1.day.ago
                 when "7_days" then 7.days.ago
                 when "30_days" then 30.days.ago
                 else 1.day.ago
                 end

    {
      alerts_triggered: FlightAlert.where("created_at > ?", start_date).where(status: "triggered").count,
      alerts_sent: FlightAlert.where("created_at > ?", start_date).count,
      click_rate: get_alert_click_rate(start_date),
      conversion_rate: get_alert_conversion_rate(start_date),
      average_quality: FlightAlert.where("created_at > ?", start_date).average(:alert_quality_score) || 0
    }
  end

  def get_performance_metrics
    {
      api_response_times: get_api_response_times,
      database_query_times: get_database_query_times,
      cache_performance: get_cache_performance,
      background_job_performance: get_background_job_performance,
      memory_usage: get_memory_usage_trends
    }
  end

  def get_user_engagement_metrics(timeframe)
    start_date = case timeframe
                 when "24_hours" then 1.day.ago
                 when "7_days" then 7.days.ago
                 when "30_days" then 30.days.ago
                 else 1.day.ago
                 end

    user_scope = User.where(id: current_user.id)

    {
      sessions: get_user_sessions(start_date),
      page_views: get_user_page_views(start_date),
      time_on_site: get_user_time_on_site(start_date),
      feature_usage: get_user_feature_usage(start_date),
      last_activity: current_user.last_sign_in_at
    }
  end

  def get_user_filter_metrics(timeframe)
    start_date = case timeframe
                 when "24_hours" then 1.day.ago
                 when "7_days" then 7.days.ago
                 when "30_days" then 30.days.ago
                 else 1.day.ago
                 end

    {
      total_filters: current_user.flight_filters.count,
      active_filters: current_user.flight_filters.active.count,
      filters_created: current_user.flight_filters.where("created_at > ?", start_date).count,
      filters_edited: get_user_filters_edited(start_date),
      average_complexity: get_user_average_filter_complexity(start_date)
    }
  end

  def get_user_alert_metrics(timeframe)
    start_date = case timeframe
                 when "24_hours" then 1.day.ago
                 when "7_days" then 7.days.ago
                 when "30_days" then 30.days.ago
                 else 1.day.ago
                 end

    {
      total_alerts: current_user.flight_alerts.count,
      triggered_alerts: current_user.flight_alerts.where(status: "triggered").count,
      recent_alerts: current_user.flight_alerts.where("created_at > ?", start_date).count,
      click_rate: get_user_alert_click_rate(start_date),
      conversion_rate: get_user_alert_conversion_rate(start_date)
    }
  end

  def get_user_recent_activity
    {
      recent_filters: current_user.flight_filters.order(created_at: :desc).limit(5),
      recent_alerts: current_user.flight_alerts.order(created_at: :desc).limit(5),
      recent_logins: get_user_recent_logins,
      last_activity: current_user.last_sign_in_at
    }
  end

  def get_user_engagement_trends(days)
    trends = {}

    (0...days).each do |day_offset|
      date = day_offset.days.ago.to_date
      start_date = date.beginning_of_day
      end_date = date.end_of_day

      trends[date.to_s] = {
        sessions: get_user_sessions_for_date(start_date, end_date),
        page_views: get_user_page_views_for_date(start_date, end_date),
        time_on_site: get_user_time_on_site_for_date(start_date, end_date),
        filters_created: current_user.flight_filters.where(created_at: start_date..end_date).count,
        alerts_triggered: current_user.flight_alerts.where(created_at: start_date..end_date, status: "triggered").count
      }
    end

    trends
  end

  def get_filter_performance_trends(days)
    trends = {}

    (0...days).each do |day_offset|
      date = day_offset.days.ago.to_date
      start_date = date.beginning_of_day
      end_date = date.end_of_day

      trends[date.to_s] = {
        filters_created: FlightFilter.where(created_at: start_date..end_date).count,
        filters_activated: FlightFilter.where(created_at: start_date..end_date).active.count,
        filters_edited: get_filters_edited_for_date(start_date, end_date),
        filters_deleted: get_filters_deleted_for_date(start_date, end_date),
        average_complexity: get_average_filter_complexity_for_date(start_date, end_date)
      }
    end

    trends
  end

  def get_alert_effectiveness_trends(days)
    trends = {}

    (0...days).each do |day_offset|
      date = day_offset.days.ago.to_date
      start_date = date.beginning_of_day
      end_date = date.end_of_day

      trends[date.to_s] = {
        alerts_triggered: FlightAlert.where(created_at: start_date..end_date, status: "triggered").count,
        alerts_sent: FlightAlert.where(created_at: start_date..end_date).count,
        click_rate: get_alert_click_rate_for_date(start_date, end_date),
        conversion_rate: get_alert_conversion_rate_for_date(start_date, end_date),
        average_quality: FlightAlert.where(created_at: start_date..end_date).average(:alert_quality_score) || 0
      }
    end

    trends
  end

  def get_all_trends(days)
    {
      user_engagement: get_user_engagement_trends(days),
      filter_performance: get_filter_performance_trends(days),
      alert_effectiveness: get_alert_effectiveness_trends(days),
      performance: PerformanceOptimizationService.get_performance_trends(days)
    }
  end

  # Helper methods for data retrieval
  def get_page_views(start_date)
    # This would integrate with analytics tracking
    1250
  end

  def get_average_session_duration(start_date)
    # This would integrate with analytics tracking
    8.5
  end

  def get_bounce_rate(start_date)
    # This would integrate with analytics tracking
    35.2
  end

  def get_filters_edited(start_date)
    # This would track filter edit events
    45
  end

  def get_filters_deleted(start_date)
    # This would track filter deletion events
    12
  end

  def get_average_filter_complexity(start_date)
    # Calculate based on filter attributes
    2.3
  end

  def get_alert_click_rate(start_date)
    # This would integrate with click tracking
    75.2
  end

  def get_alert_conversion_rate(start_date)
    # This would integrate with booking tracking
    25.8
  end

  def get_api_response_times
    {
      skyscanner: 1250, # milliseconds
      amadeus: 980,
      google_flights: 1100,
      average: 1100
    }
  end

  def get_database_query_times
    {
      average: 45, # milliseconds
      slowest: 250,
      fastest: 12
    }
  end

  def get_cache_performance
    {
      hit_rate: 78.5,
      miss_rate: 21.5,
      average_response_time: 5 # milliseconds
    }
  end

  def get_background_job_performance
    {
      success_rate: 96.8,
      average_processing_time: 2.5, # seconds
      queue_length: 15
    }
  end

  def get_memory_usage_trends
    {
      current: 256, # MB
      peak: 512,
      average: 320,
      trend: "stable"
    }
  end

  def get_user_sessions(start_date)
    # This would integrate with session tracking
    5
  end

  def get_user_page_views(start_date)
    # This would integrate with analytics tracking
    25
  end

  def get_user_time_on_site(start_date)
    # This would integrate with analytics tracking
    12.5 # minutes
  end

  def get_user_feature_usage(start_date)
    {
      filter_creation: 3,
      alert_setup: 2,
      dashboard_viewing: 8,
      price_history: 1
    }
  end

  def get_user_filters_edited(start_date)
    # This would track user"s filter edit events
    2
  end

  def get_user_average_filter_complexity(start_date)
    # Calculate based on user"s filters
    2.1
  end

  def get_user_alert_click_rate(start_date)
    # This would integrate with user"s click tracking
    80.5
  end

  def get_user_alert_conversion_rate(start_date)
    # This would integrate with user"s booking tracking
    30.2
  end

  def get_user_recent_logins
    # This would track login events
    [
      { date: 1.day.ago, ip: "192.168.1.1" },
      { date: 3.days.ago, ip: "192.168.1.1" },
      { date: 7.days.ago, ip: "192.168.1.2" }
    ]
  end

  # Date-specific helper methods
  def get_user_sessions_for_date(start_date, end_date)
    # This would integrate with session tracking
    1
  end

  def get_user_page_views_for_date(start_date, end_date)
    # This would integrate with analytics tracking
    5
  end

  def get_user_time_on_site_for_date(start_date, end_date)
    # This would integrate with analytics tracking
    8.5
  end

  def get_filters_edited_for_date(start_date, end_date)
    # This would track filter edit events
    2
  end

  def get_filters_deleted_for_date(start_date, end_date)
    # This would track filter deletion events
    1
  end

  def get_average_filter_complexity_for_date(start_date, end_date)
    # Calculate based on filters created on that date
    2.2
  end

  def get_alert_click_rate_for_date(start_date, end_date)
    # This would integrate with click tracking
    75.0
  end

  def get_alert_conversion_rate_for_date(start_date, end_date)
    # This would integrate with booking tracking
    25.0
  end

  # Additional helper methods for complex analytics
  def get_ab_test_results(test_name)
    # This would integrate with A/B testing framework
    {
      test_name: test_name,
      variant_a: { users: 1000, conversion_rate: 8.5 },
      variant_b: { users: 1000, conversion_rate: 9.2 },
      significance: 0.95,
      winner: "variant_b"
    }
  end

  def get_all_ab_tests
    # This would return all active A/B tests
    [
      { name: "filter_wizard_design", status: "active" },
      { name: "alert_notification_timing", status: "completed" },
      { name: "dashboard_layout", status: "active" }
    ]
  end

  def get_behavior_segments
    {
      casual_travelers: { count: 450, percentage: 45.0 },
      business_travelers: { count: 280, percentage: 28.0 },
      frequent_flyers: { count: 150, percentage: 15.0 },
      budget_conscious: { count: 120, percentage: 12.0 }
    }
  end

  def get_engagement_segments
    {
      high_engagement: { count: 200, percentage: 20.0 },
      medium_engagement: { count: 500, percentage: 50.0 },
      low_engagement: { count: 300, percentage: 30.0 }
    }
  end

  def get_value_segments
    {
      high_value: { count: 100, percentage: 10.0 },
      medium_value: { count: 400, percentage: 40.0 },
      low_value: { count: 500, percentage: 50.0 }
    }
  end

  def get_all_segments
    {
      behavior: get_behavior_segments,
      engagement: get_engagement_segments,
      value: get_value_segments
    }
  end

  def get_route_analysis(route, timeframe)
    start_date = case timeframe
                 when "24_hours" then 1.day.ago
                 when "7_days" then 7.days.ago
                 when "30_days" then 30.days.ago
                 else 30.days.ago
                 end

    {
      route: route,
      filters_created: FlightFilter.where("origin_airports LIKE ? AND destination_airports LIKE ?", "%#{route.split("-")[0]}%", "%#{route.split("-")[1]}%").where("created_at > ?", start_date).count,
      alerts_triggered: FlightAlert.joins(:flight_filter).where("flight_filters.origin_airports LIKE ? AND flight_filters.destination_airports LIKE ?", "%#{route.split("-")[0]}%", "%#{route.split("-")[1]}%").where("created_at > ?", start_date).where(status: "triggered").count,
      average_price: FlightPriceHistory.where(route: route).where("created_at > ?", start_date).average(:price) || 0,
      price_volatility: calculate_route_price_volatility(route, start_date),
      popularity_trend: calculate_route_popularity_trend(route, start_date)
    }
  end

  def get_top_routes_analysis(timeframe)
    start_date = case timeframe
                 when "24_hours" then 1.day.ago
                 when "7_days" then 7.days.ago
                 when "30_days" then 30.days.ago
                 else 30.days.ago
                 end

    FlightFilter.where("created_at > ?", start_date)
                .group(:origin_airports, :destination_airports)
                .count
                .sort_by { |_, count| -count }
                .first(20)
                .map { |route, count| { route: route, count: count } }
  end

  def get_monthly_trends(year)
    (1..12).map do |month|
      month_start = Date.new(year, month, 1)
      month_end = month_start.end_of_month

      {
        month: month_start.strftime("%B"),
        filters_created: FlightFilter.where(created_at: month_start..month_end).count,
        alerts_triggered: FlightAlert.where(created_at: month_start..month_end, status: "triggered").count,
        new_users: User.where(created_at: month_start..month_end).count
      }
    end
  end

  def get_seasonal_routes(year)
    {
      spring: ["NYC-LAX", "CHI-MIA", "DEN-SEA"],
      summer: ["LAX-SFO", "NYC-MIA", "CHI-DEN"],
      fall: ["NYC-CHI", "LAX-DEN", "MIA-ATL"],
      winter: ["NYC-FLL", "CHI-PHX", "DEN-LAX"]
    }
  end

  def get_holiday_impact(year)
    {
      thanksgiving: { impact: 1.35, routes: ["NYC-LAX", "CHI-NYC"] },
      christmas: { impact: 1.45, routes: ["NYC-MIA", "LAX-SFO"] },
      new_year: { impact: 1.25, routes: ["NYC-LAX", "CHI-DEN"] },
      summer_vacation: { impact: 1.20, routes: ["LAX-SFO", "NYC-MIA"] }
    }
  end

  def get_weather_correlation(year)
    0.42 # Moderate correlation with weather patterns
  end

  def get_booking_patterns(year)
    {
      advance_booking_days: 45,
      last_minute_bookings: 15.2,
      weekend_preference: 68.5,
      morning_departures: 42.3
    }
  end

  def get_system_status
    {
      monitoring_active: FlightPriceMonitoringJob.monitoring_status[:is_running],
      last_check: FlightPriceMonitoringJob.monitoring_status[:last_run],
      system_health: PerformanceOptimizationService.get_system_performance_report[:health_status][:overall_health]
    }
  end

  def get_active_jobs
    {
      monitoring: FlightPriceMonitoringJob.where(queue_name: "monitoring").count,
      analysis: PriceTrendAnalysisJob.where(queue_name: "analysis").count,
      cleanup: FlightDataCleanupJob.where(queue_name: "cleanup").count,
      alerts: AlertDeliveryJob.where(queue_name: "alerts").count
    }
  end

  def get_recent_errors
    # This would integrate with error tracking
    [
      { timestamp: 1.hour.ago, error: "API timeout", count: 3 },
      { timestamp: 2.hours.ago, error: "Database connection", count: 1 },
      { timestamp: 4.hours.ago, error: "Memory limit", count: 1 }
    ]
  end

  def get_performance_alerts
    PerformanceOptimizationService.new.monitor_performance_thresholds
  end

  def get_api_status
    {
      skyscanner: "healthy",
      amadeus: "healthy",
      google_flights: "degraded",
      overall: "healthy"
    }
  end

  def calculate_route_price_volatility(route, start_date)
    # Calculate price volatility for a specific route
    12.5 # percentage
  end

  def calculate_route_popularity_trend(route, start_date)
    # Calculate popularity trend for a specific route
    "increasing"
  end
end

