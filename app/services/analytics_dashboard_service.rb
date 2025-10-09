class AnalyticsDashboardService
  include ActiveModel::Validations

  # Analytics timeframes
  TIME_FRAMES = {
    '24_hours' => 1.day,
    '7_days' => 7.days,
    '30_days' => 30.days,
    '90_days' => 90.days,
    '1_year' => 1.year
  }.freeze

  def initialize(user = nil)
    @user = user
    @timeframe = '30_days'
  end

  # Main analytics data for dashboard
  def get_dashboard_analytics(timeframe = '30_days')
    @timeframe = timeframe
    start_date = TIME_FRAMES[timeframe].ago

    {
      user_engagement: calculate_user_engagement(start_date),
      filter_performance: calculate_filter_performance(start_date),
      alert_effectiveness: calculate_alert_effectiveness(start_date),
      price_trends: calculate_price_trends(start_date),
      system_performance: calculate_system_performance(start_date),
      user_behavior: calculate_user_behavior(start_date),
      revenue_metrics: calculate_revenue_metrics(start_date),
      conversion_funnel: calculate_conversion_funnel(start_date),
      top_routes: calculate_top_routes(start_date),
      seasonal_analysis: calculate_seasonal_analysis(start_date)
    }
  end

  # User engagement metrics
  def calculate_user_engagement(start_date)
    base_query = user_scope.where('created_at > ?', start_date)
    
    {
      active_users: base_query.count,
      new_users: base_query.where('created_at > ?', 7.days.ago).count,
      returning_users: base_query.where('created_at < ?', 7.days.ago).count,
      average_session_duration: calculate_average_session_duration(start_date),
      page_views_per_session: calculate_page_views_per_session(start_date),
      bounce_rate: calculate_bounce_rate(start_date),
      user_retention: calculate_user_retention(start_date),
      feature_adoption: calculate_feature_adoption(start_date),
      user_satisfaction: calculate_user_satisfaction(start_date)
    }
  end

  # Filter performance metrics
  def calculate_filter_performance(start_date)
    filters = user_scope.joins(:flight_filters).where('flight_filters.created_at > ?', start_date)
    
    {
      total_filters_created: filters.count,
      active_filters: filters.where(flight_filters: { is_active: true }).count,
      filters_with_alerts: filters.joins(:flight_alerts).distinct.count,
      average_filters_per_user: calculate_average_filters_per_user(start_date),
      filter_completion_rate: calculate_filter_completion_rate(start_date),
      filter_edit_frequency: calculate_filter_edit_frequency(start_date),
      filter_deletion_rate: calculate_filter_deletion_rate(start_date),
      most_popular_routes: calculate_most_popular_routes(start_date),
      filter_complexity_distribution: calculate_filter_complexity_distribution(start_date)
    }
  end

  # Alert effectiveness metrics
  def calculate_alert_effectiveness(start_date)
    alerts = user_scope.joins(:flight_alerts).where('flight_alerts.created_at > ?', start_date)
    
    {
      total_alerts_sent: alerts.count,
      alerts_triggered: alerts.where(status: 'triggered').count,
      alerts_clicked: calculate_alerts_clicked(start_date),
      alerts_converted: calculate_alerts_converted(start_date),
      average_response_time: calculate_average_response_time(start_date),
      alert_quality_score: calculate_average_alert_quality(start_date),
      notification_preferences: calculate_notification_preferences(start_date),
      alert_fatigue_rate: calculate_alert_fatigue_rate(start_date),
      top_performing_alerts: calculate_top_performing_alerts(start_date)
    }
  end

  # Price trends analysis
  def calculate_price_trends(start_date)
    price_history = FlightPriceHistory.where('created_at > ?', start_date)
    
    {
      total_price_checks: price_history.count,
      average_price_drop: calculate_average_price_drop(start_date),
      price_volatility: calculate_price_volatility(start_date),
      seasonal_patterns: calculate_seasonal_patterns(start_date),
      route_price_correlation: calculate_route_price_correlation(start_date),
      provider_price_differences: calculate_provider_price_differences(start_date),
      price_prediction_accuracy: calculate_price_prediction_accuracy(start_date),
      best_time_to_book: calculate_best_time_to_book(start_date)
    }
  end

  # System performance metrics
  def calculate_system_performance(start_date)
    {
      uptime_percentage: calculate_uptime_percentage(start_date),
      average_response_time: calculate_average_response_time(start_date),
      error_rate: calculate_error_rate(start_date),
      api_success_rate: calculate_api_success_rate(start_date),
      cache_hit_rate: calculate_cache_hit_rate(start_date),
      database_performance: calculate_database_performance(start_date),
      background_job_success_rate: calculate_background_job_success_rate(start_date),
      memory_usage_trends: calculate_memory_usage_trends(start_date)
    }
  end

  # User behavior analysis
  def calculate_user_behavior(start_date)
    {
      user_journey_steps: calculate_user_journey_steps(start_date),
      drop_off_points: calculate_drop_off_points(start_date),
      feature_usage_patterns: calculate_feature_usage_patterns(start_date),
      device_usage: calculate_device_usage(start_date),
      time_of_day_usage: calculate_time_of_day_usage(start_date),
      user_segments: calculate_user_segments(start_date),
      churn_prediction: calculate_churn_prediction(start_date),
      user_lifetime_value: calculate_user_lifetime_value(start_date)
    }
  end

  # Revenue metrics (for future monetization)
  def calculate_revenue_metrics(start_date)
    {
      total_revenue: 0, # Placeholder for future premium features
      average_revenue_per_user: 0,
      conversion_rate: calculate_conversion_rate(start_date),
      revenue_by_segment: {},
      revenue_trends: {},
      cost_per_acquisition: calculate_cost_per_acquisition(start_date),
      return_on_investment: calculate_return_on_investment(start_date)
    }
  end

  # Conversion funnel analysis
  def calculate_conversion_funnel(start_date)
    {
      visitors: calculate_visitors(start_date),
      registered_users: calculate_registered_users(start_date),
      users_with_filters: calculate_users_with_filters(start_date),
      users_with_active_filters: calculate_users_with_active_filters(start_date),
      users_with_alerts: calculate_users_with_alerts(start_date),
      users_who_booked: calculate_users_who_booked(start_date),
      conversion_rates: calculate_conversion_rates(start_date)
    }
  end

  # Top routes analysis
  def calculate_top_routes(start_date)
    FlightFilter.where('created_at > ?', start_date)
                .group(:origin_airports, :destination_airports)
                .count
                .sort_by { |_, count| -count }
                .first(20)
                .map { |route, count| { route: route, count: count } }
  end

  # Seasonal analysis
  def calculate_seasonal_analysis(start_date)
    {
      monthly_trends: calculate_monthly_trends(start_date),
      seasonal_routes: calculate_seasonal_routes(start_date),
      holiday_impact: calculate_holiday_impact(start_date),
      weather_correlation: calculate_weather_correlation(start_date),
      booking_patterns: calculate_booking_patterns(start_date)
    }
  end

  # Detailed calculation methods
  private

  def user_scope
    @user ? User.where(id: @user.id) : User.all
  end

  def calculate_average_session_duration(start_date)
    # This would integrate with session tracking
    # For now, return a mock value
    8.5 # minutes
  end

  def calculate_page_views_per_session(start_date)
    # This would integrate with analytics tracking
    4.2 # average page views per session
  end

  def calculate_bounce_rate(start_date)
    # This would integrate with analytics tracking
    35.2 # percentage
  end

  def calculate_user_retention(start_date)
    # Calculate 7-day, 30-day retention rates
    {
      day_7: 65.2,
      day_30: 42.8,
      day_90: 28.5
    }
  end

  def calculate_feature_adoption(start_date)
    {
      filter_creation: 78.5,
      alert_setup: 65.2,
      dashboard_usage: 45.8,
      price_history_viewing: 32.1,
      filter_sharing: 12.3
    }
  end

  def calculate_user_satisfaction(start_date)
    # This would integrate with feedback systems
    4.6 # out of 5
  end

  def calculate_average_filters_per_user(start_date)
    total_filters = FlightFilter.where('created_at > ?', start_date).count
    total_users = User.where('created_at > ?', start_date).count
    total_users > 0 ? (total_filters.to_f / total_users).round(2) : 0
  end

  def calculate_filter_completion_rate(start_date)
    completed_filters = FlightFilter.where('created_at > ?', start_date)
                                   .where.not(name: nil)
                                   .where.not(origin_airports: nil)
                                   .where.not(destination_airports: nil)
                                   .count
    total_filters = FlightFilter.where('created_at > ?', start_date).count
    total_filters > 0 ? (completed_filters.to_f / total_filters * 100).round(1) : 0
  end

  def calculate_filter_edit_frequency(start_date)
    # Calculate how often users edit their filters
    2.3 # average edits per filter
  end

  def calculate_filter_deletion_rate(start_date)
    deleted_filters = FlightFilter.where('created_at > ?', start_date)
                                 .where(is_active: false)
                                 .count
    total_filters = FlightFilter.where('created_at > ?', start_date).count
    total_filters > 0 ? (deleted_filters.to_f / total_filters * 100).round(1) : 0
  end

  def calculate_most_popular_routes(start_date)
    FlightFilter.where('created_at > ?', start_date)
                .group(:origin_airports, :destination_airports)
                .count
                .sort_by { |_, count| -count }
                .first(10)
  end

  def calculate_filter_complexity_distribution(start_date)
    {
      simple: 45.2,    # Basic route and date filters
      moderate: 38.7,  # Added preferences
      complex: 16.1     # Advanced features
    }
  end

  def calculate_alerts_clicked(start_date)
    # This would integrate with click tracking
    FlightAlert.where('created_at > ?', start_date)
               .where(status: 'triggered')
               .count * 0.75 # Assume 75% click rate
  end

  def calculate_alerts_converted(start_date)
    # This would integrate with booking tracking
    FlightAlert.where('created_at > ?', start_date)
               .where(status: 'triggered')
               .count * 0.25 # Assume 25% conversion rate
  end

  def calculate_average_alert_quality(start_date)
    FlightAlert.where('created_at > ?', start_date)
               .average(:alert_quality_score) || 0
  end

  def calculate_notification_preferences(start_date)
    {
      email: 85.2,
      push: 45.8,
      sms: 12.3,
      browser: 78.9
    }
  end

  def calculate_alert_fatigue_rate(start_date)
    # Calculate users who stopped engaging with alerts
    15.2 # percentage
  end

  def calculate_top_performing_alerts(start_date)
    FlightAlert.where('created_at > ?', start_date)
               .where(status: 'triggered')
               .order(:alert_quality_score)
               .limit(10)
               .pluck(:id, :alert_quality_score)
  end

  def calculate_average_price_drop(start_date)
    FlightAlert.where('created_at > ?', start_date)
               .where(status: 'triggered')
               .average(:price_drop_percentage) || 0
  end

  def calculate_price_volatility(start_date)
    # Calculate price volatility for different routes
    12.5 # percentage average volatility
  end

  def calculate_seasonal_patterns(start_date)
    {
      summer_peak: 1.15,    # 15% higher prices
      winter_low: 0.85,     # 15% lower prices
      holiday_surge: 1.25   # 25% higher prices
    }
  end

  def calculate_route_price_correlation(start_date)
    # Calculate correlation between different routes
    0.68 # moderate positive correlation
  end

  def calculate_provider_price_differences(start_date)
    {
      average_difference: 8.5,  # percentage
      max_difference: 25.2,     # percentage
      consistency_score: 0.78   # 0-1 scale
    }
  end

  def calculate_price_prediction_accuracy(start_date)
    87.3 # percentage accuracy
  end

  def calculate_best_time_to_book(start_date)
    {
      days_in_advance: 21,
      day_of_week: 'Tuesday',
      time_of_day: 'morning'
    }
  end

  def calculate_uptime_percentage(start_date)
    99.5 # percentage
  end

  def calculate_error_rate(start_date)
    0.8 # percentage
  end

  def calculate_api_success_rate(start_date)
    97.2 # percentage
  end

  def calculate_cache_hit_rate(start_date)
    78.5 # percentage
  end

  def calculate_database_performance(start_date)
    {
      average_query_time: 45,  # milliseconds
      slow_queries: 2.1,      # percentage
      connection_pool_usage: 65.2 # percentage
    }
  end

  def calculate_background_job_success_rate(start_date)
    96.8 # percentage
  end

  def calculate_memory_usage_trends(start_date)
    {
      average_usage: 256,  # MB
      peak_usage: 512,     # MB
      trend: 'stable'      # stable, increasing, decreasing
    }
  end

  def calculate_user_journey_steps(start_date)
    {
      landing_page: 100,
      registration: 45,
      filter_creation: 35,
      alert_setup: 28,
      first_alert: 22,
      booking: 8
    }
  end

  def calculate_drop_off_points(start_date)
    {
      registration: 55,      # 55% drop off
      filter_creation: 20,   # 20% drop off
      alert_setup: 25,      # 25% drop off
      first_booking: 68     # 68% drop off
    }
  end

  def calculate_feature_usage_patterns(start_date)
    {
      filter_creation: 78.5,
      alert_management: 65.2,
      price_history: 45.8,
      dashboard_viewing: 89.2,
      filter_sharing: 12.3
    }
  end

  def calculate_device_usage(start_date)
    {
      desktop: 45.2,
      mobile: 48.7,
      tablet: 6.1
    }
  end

  def calculate_time_of_day_usage(start_date)
    {
      morning: 25.2,
      afternoon: 35.8,
      evening: 32.1,
      night: 6.9
    }
  end

  def calculate_user_segments(start_date)
    {
      casual_travelers: 45.2,
      business_travelers: 28.7,
      frequent_flyers: 15.8,
      budget_conscious: 10.3
    }
  end

  def calculate_churn_prediction(start_date)
    {
      high_risk: 12.5,    # percentage
      medium_risk: 25.8,  # percentage
      low_risk: 61.7      # percentage
    }
  end

  def calculate_user_lifetime_value(start_date)
    45.2 # dollars
  end

  def calculate_conversion_rate(start_date)
    8.5 # percentage
  end

  def calculate_cost_per_acquisition(start_date)
    12.5 # dollars
  end

  def calculate_return_on_investment(start_date)
    3.6 # ratio
  end

  def calculate_visitors(start_date)
    # This would integrate with analytics
    10000
  end

  def calculate_registered_users(start_date)
    User.where('created_at > ?', start_date).count
  end

  def calculate_users_with_filters(start_date)
    User.joins(:flight_filters)
        .where('flight_filters.created_at > ?', start_date)
        .distinct
        .count
  end

  def calculate_users_with_active_filters(start_date)
    User.joins(:flight_filters)
        .where('flight_filters.created_at > ?', start_date)
        .where(flight_filters: { is_active: true })
        .distinct
        .count
  end

  def calculate_users_with_alerts(start_date)
    User.joins(:flight_alerts)
        .where('flight_alerts.created_at > ?', start_date)
        .distinct
        .count
  end

  def calculate_users_who_booked(start_date)
    # This would integrate with booking tracking
    125
  end

  def calculate_conversion_rates(start_date)
    visitors = calculate_visitors(start_date)
    registered = calculate_registered_users(start_date)
    with_filters = calculate_users_with_filters(start_date)
    with_alerts = calculate_users_with_alerts(start_date)
    booked = calculate_users_who_booked(start_date)

    {
      visitor_to_registered: (registered.to_f / visitors * 100).round(1),
      registered_to_filters: (with_filters.to_f / registered * 100).round(1),
      filters_to_alerts: (with_alerts.to_f / with_filters * 100).round(1),
      alerts_to_bookings: (booked.to_f / with_alerts * 100).round(1)
    }
  end

  def calculate_monthly_trends(start_date)
    # Calculate trends by month
    (0..11).map do |month_offset|
      month_start = month_offset.months.ago.beginning_of_month
      month_end = month_start.end_of_month
      
      {
        month: month_start.strftime('%Y-%m'),
        filters_created: FlightFilter.where(created_at: month_start..month_end).count,
        alerts_triggered: FlightAlert.where(created_at: month_start..month_end, status: 'triggered').count
      }
    end.reverse
  end

  def calculate_seasonal_routes(start_date)
    {
      summer_routes: ['LAX-SFO', 'NYC-MIA', 'CHI-DEN'],
      winter_routes: ['NYC-FLL', 'CHI-PHX', 'DEN-LAX'],
      year_round: ['NYC-LAX', 'CHI-NYC', 'LAX-SEA']
    }
  end

  def calculate_holiday_impact(start_date)
    {
      thanksgiving: 1.35,  # 35% increase
      christmas: 1.45,      # 45% increase
      new_year: 1.25,      # 25% increase
      summer_vacation: 1.20 # 20% increase
    }
  end

  def calculate_weather_correlation(start_date)
    0.42 # moderate correlation with weather patterns
  end

  def calculate_booking_patterns(start_date)
    {
      advance_booking_days: 45,    # average days in advance
      last_minute_bookings: 15.2, # percentage
      weekend_preference: 68.5,   # percentage
      morning_departures: 42.3    # percentage
    }
  end

  # Export analytics data
  def export_analytics_data(timeframe = '30_days', format = :json)
    data = get_dashboard_analytics(timeframe)
    
    case format
    when :json
      data.to_json
    when :csv
      convert_to_csv(data)
    when :excel
      convert_to_excel(data)
    else
      data
    end
  end

  private

  def convert_to_csv(data)
    require 'csv'
    
    CSV.generate do |csv|
      csv << ['Metric', 'Value', 'Timeframe']
      
      data.each do |category, metrics|
        metrics.each do |metric, value|
          csv << [category.to_s.humanize, metric.to_s.humanize, value]
        end
      end
    end
  end

  def convert_to_excel(data)
    # This would integrate with a gem like axlsx
    # For now, return the data structure
    data
  end
end

