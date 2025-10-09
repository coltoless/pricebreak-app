class AlertQualityService
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :alert, type: Object
  attribute :timeframe, type: String, default: '30_days'

  # Quality scoring weights
  PRICE_ACCURACY_WEIGHT = 0.3
  NOTIFICATION_SUCCESS_WEIGHT = 0.25
  USER_ENGAGEMENT_WEIGHT = 0.2
  DATA_FRESHNESS_WEIGHT = 0.15
  TREND_ANALYSIS_WEIGHT = 0.1

  def initialize(alert, options = {})
    @alert = alert
    @timeframe = options[:timeframe] || '30_days'
  end

  # Calculate comprehensive quality score
  def calculate_quality_score
    return 0.0 unless alert.present?

    scores = {
      price_accuracy: calculate_price_accuracy_score,
      notification_success: calculate_notification_success_score,
      user_engagement: calculate_user_engagement_score,
      data_freshness: calculate_data_freshness_score,
      trend_analysis: calculate_trend_analysis_score
    }

    weighted_score = (
      scores[:price_accuracy] * PRICE_ACCURACY_WEIGHT +
      scores[:notification_success] * NOTIFICATION_SUCCESS_WEIGHT +
      scores[:user_engagement] * USER_ENGAGEMENT_WEIGHT +
      scores[:data_freshness] * DATA_FRESHNESS_WEIGHT +
      scores[:trend_analysis] * TREND_ANALYSIS_WEIGHT
    )

    # Ensure score is between 0 and 1
    [weighted_score, 1.0].min.round(3)
  end

  # Get detailed quality analysis
  def quality_analysis
    {
      overall_score: calculate_quality_score,
      components: {
        price_accuracy: {
          score: calculate_price_accuracy_score,
          weight: PRICE_ACCURACY_WEIGHT,
          details: analyze_price_accuracy
        },
        notification_success: {
          score: calculate_notification_success_score,
          weight: NOTIFICATION_SUCCESS_WEIGHT,
          details: analyze_notification_success
        },
        user_engagement: {
          score: calculate_user_engagement_score,
          weight: USER_ENGAGEMENT_WEIGHT,
          details: analyze_user_engagement
        },
        data_freshness: {
          score: calculate_data_freshness_score,
          weight: DATA_FRESHNESS_WEIGHT,
          details: analyze_data_freshness
        },
        trend_analysis: {
          score: calculate_trend_analysis_score,
          weight: TREND_ANALYSIS_WEIGHT,
          details: analyze_trend_analysis
        }
      },
      recommendations: generate_recommendations,
      performance_metrics: calculate_performance_metrics
    }
  end

  # Update alert quality score
  def update_alert_quality
    new_score = calculate_quality_score
    old_score = alert.alert_quality_score || 0.0
    
    alert.update!(alert_quality_score: new_score)
    
    # Log quality change if significant
    if (new_score - old_score).abs > 0.1
      log_quality_change(old_score, new_score)
    end
    
    new_score
  end

  # Batch update quality scores for multiple alerts
  def self.batch_update_quality(alert_ids, timeframe = '30_days')
    results = { updated: 0, errors: [] }
    
    FlightAlert.where(id: alert_ids).find_each do |alert|
      begin
        service = new(alert, timeframe: timeframe)
        service.update_alert_quality
        results[:updated] += 1
      rescue => e
        results[:errors] << { alert_id: alert.id, error: e.message }
      end
    end
    
    results
  end

  # Get quality trends over time
  def quality_trends
    return {} unless alert.notification_history.present?
    
    # Analyze quality over time based on notification history
    trends = {
      improvement_rate: calculate_improvement_rate,
      consistency_score: calculate_consistency_score,
      recent_performance: calculate_recent_performance,
      peak_performance: calculate_peak_performance
    }
    
    trends
  end

  # Generate quality recommendations
  def generate_recommendations
    recommendations = []
    analysis = quality_analysis
    
    # Price accuracy recommendations
    if analysis[:components][:price_accuracy][:score] < 0.7
      recommendations << {
        category: 'price_accuracy',
        priority: 'high',
        message: 'Consider adjusting price target or checking data sources',
        action: 'review_price_settings'
      }
    end
    
    # Notification success recommendations
    if analysis[:components][:notification_success][:score] < 0.8
      recommendations << {
        category: 'notifications',
        priority: 'medium',
        message: 'Check notification settings and delivery channels',
        action: 'review_notification_settings'
      }
    end
    
    # User engagement recommendations
    if analysis[:components][:user_engagement][:score] < 0.6
      recommendations << {
        category: 'engagement',
        priority: 'medium',
        message: 'Alert may not be relevant - consider updating criteria',
        action: 'review_alert_criteria'
      }
    end
    
    # Data freshness recommendations
    if analysis[:components][:data_freshness][:score] < 0.5
      recommendations << {
        category: 'data_freshness',
        priority: 'high',
        message: 'Alert data is stale - check monitoring frequency',
        action: 'increase_monitoring_frequency'
      }
    end
    
    recommendations
  end

  private

  def calculate_price_accuracy_score
    return 0.5 unless alert.current_price && alert.target_price
    
    # Compare current price with target price accuracy
    price_ratio = alert.current_price.to_f / alert.target_price.to_f
    
    case price_ratio
    when 0.0..0.5 then 1.0  # Price is 50% or less of target - excellent
    when 0.5..0.7 then 0.8  # Price is 50-70% of target - good
    when 0.7..0.9 then 0.6  # Price is 70-90% of target - fair
    when 0.9..1.1 then 0.4  # Price is close to target - poor
    else 0.2  # Price is above target - very poor
    end
  end

  def calculate_notification_success_score
    return 0.5 unless alert.notification_history.present?
    
    total_notifications = alert.notification_history.count
    successful_notifications = alert.notification_history.count { |n| n['success'] == true }
    
    return 0.0 if total_notifications == 0
    
    success_rate = successful_notifications.to_f / total_notifications
    success_rate
  end

  def calculate_user_engagement_score
    # This would integrate with actual user engagement data
    # For now, use a placeholder calculation based on alert activity
    
    engagement_factors = []
    
    # Factor 1: Alert has been triggered
    engagement_factors << 0.3 if alert.status == 'triggered'
    
    # Factor 2: Recent activity
    if alert.last_checked && alert.last_checked > 1.week.ago
      engagement_factors << 0.3
    end
    
    # Factor 3: Quality score history
    if alert.alert_quality_score && alert.alert_quality_score > 0.7
      engagement_factors << 0.4
    end
    
    engagement_factors.sum
  end

  def calculate_data_freshness_score
    return 0.0 unless alert.last_checked
    
    hours_since_last_check = (Time.current - alert.last_checked) / 1.hour
    
    case hours_since_last_check
    when 0..1 then 1.0      # Very fresh
    when 1..6 then 0.8      # Fresh
    when 6..24 then 0.6     # Moderate
    when 24..72 then 0.4    # Stale
    else 0.2                 # Very stale
    end
  end

  def calculate_trend_analysis_score
    return 0.5 unless alert.notification_history.present?
    
    # Analyze trend in notification success over time
    recent_notifications = alert.notification_history.last(10)
    return 0.5 if recent_notifications.empty?
    
    recent_success_rate = recent_notifications.count { |n| n['success'] == true }.to_f / recent_notifications.count
    
    # Compare with overall success rate
    overall_success_rate = calculate_notification_success_score
    
    if recent_success_rate > overall_success_rate
      0.8  # Improving trend
    elsif recent_success_rate == overall_success_rate
      0.6  # Stable trend
    else
      0.4  # Declining trend
    end
  end

  def analyze_price_accuracy
    {
      current_price: alert.current_price,
      target_price: alert.target_price,
      accuracy_percentage: calculate_price_accuracy_percentage,
      price_trend: determine_price_trend
    }
  end

  def analyze_notification_success
    return {} unless alert.notification_history.present?
    
    total = alert.notification_history.count
    successful = alert.notification_history.count { |n| n['success'] == true }
    failed = total - successful
    
    {
      total_notifications: total,
      successful_notifications: successful,
      failed_notifications: failed,
      success_rate: total > 0 ? (successful.to_f / total * 100).round(1) : 0,
      last_success: find_last_successful_notification,
      common_failure_reasons: analyze_failure_reasons
    }
  end

  def analyze_user_engagement
    {
      alert_age_days: alert.created_at ? (Time.current - alert.created_at) / 1.day : 0,
      last_activity: alert.last_checked,
      status_changes: count_status_changes,
      quality_score_trend: calculate_quality_trend
    }
  end

  def analyze_data_freshness
    {
      last_checked: alert.last_checked,
      hours_since_check: alert.last_checked ? (Time.current - alert.last_checked) / 1.hour : nil,
      freshness_level: determine_freshness_level,
      recommended_check_frequency: recommend_check_frequency
    }
  end

  def analyze_trend_analysis
    {
      improvement_trend: calculate_improvement_trend,
      consistency_score: calculate_consistency_score,
      volatility_score: calculate_volatility_score
    }
  end

  def calculate_performance_metrics
    {
      average_response_time: calculate_average_response_time,
      uptime_percentage: calculate_uptime_percentage,
      cost_efficiency: calculate_cost_efficiency,
      user_satisfaction: calculate_user_satisfaction
    }
  end

  def calculate_price_accuracy_percentage
    return 0 unless alert.current_price && alert.target_price
    
    ((alert.target_price - alert.current_price) / alert.target_price * 100).round(1)
  end

  def determine_price_trend
    # This would analyze actual price history
    'stable' # placeholder
  end

  def find_last_successful_notification
    return nil unless alert.notification_history.present?
    
    successful_notifications = alert.notification_history.select { |n| n['success'] == true }
    return nil if successful_notifications.empty?
    
    successful_notifications.max_by { |n| n['timestamp'] }['timestamp']
  end

  def analyze_failure_reasons
    return [] unless alert.notification_history.present?
    
    failed_notifications = alert.notification_history.select { |n| n['success'] == false }
    failure_reasons = failed_notifications.map { |n| n['content'] }.compact
    
    # Count common failure reasons
    failure_reasons.tally.sort_by { |_, count| -count }.first(3)
  end

  def count_status_changes
    # This would count actual status changes from audit log
    0 # placeholder
  end

  def calculate_quality_trend
    # This would analyze quality score over time
    'stable' # placeholder
  end

  def determine_freshness_level
    return 'unknown' unless alert.last_checked
    
    hours_since_check = (Time.current - alert.last_checked) / 1.hour
    
    case hours_since_check
    when 0..1 then 'very_fresh'
    when 1..6 then 'fresh'
    when 6..24 then 'moderate'
    when 24..72 then 'stale'
    else 'very_stale'
    end
  end

  def recommend_check_frequency
    case alert.status
    when 'active' then '6 hours'
    when 'triggered' then '30 minutes'
    when 'paused' then '24 hours'
    else '12 hours'
    end
  end

  def calculate_improvement_trend
    # This would analyze improvement over time
    'stable' # placeholder
  end

  def calculate_consistency_score
    # This would measure consistency of performance
    0.75 # placeholder
  end

  def calculate_volatility_score
    # This would measure volatility in performance
    0.25 # placeholder
  end

  def calculate_average_response_time
    # This would calculate based on actual response times
    2.5 # minutes
  end

  def calculate_uptime_percentage
    # This would calculate based on actual uptime
    99.5 # percentage
  end

  def calculate_cost_efficiency
    # This would calculate based on cost per successful alert
    0.85 # efficiency score
  end

  def calculate_user_satisfaction
    # This would calculate based on user feedback
    4.2 # out of 5
  end

  def calculate_improvement_rate
    # This would calculate rate of improvement over time
    0.05 # 5% improvement per week
  end

  def calculate_recent_performance
    # This would calculate recent performance metrics
    0.8 # score
  end

  def calculate_peak_performance
    # This would calculate peak performance achieved
    0.95 # score
  end

  def log_quality_change(old_score, new_score)
    # Log significant quality changes for monitoring
    Rails.logger.info "Alert #{alert.id} quality score changed from #{old_score} to #{new_score}"
    
    # Could also store in audit log or analytics system
  end
end
