class AlertIntelligenceService
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :alert, type: Object
  attribute :current_price, type: Float
  attribute :historical_data, type: Array, default: []
  attribute :user_preferences, type: Hash, default: {}

  # Smart alert timing thresholds
  URGENT_THRESHOLD = 0.15 # 15% price drop
  SIGNIFICANT_THRESHOLD = 0.08 # 8% price drop
  MINOR_THRESHOLD = 0.03 # 3% price drop
  SPAM_PREVENTION_THRESHOLD = 0.01 # 1% minimum to avoid spam

  # Timing intervals based on urgency
  URGENT_INTERVAL = 15.minutes
  SIGNIFICANT_INTERVAL = 1.hour
  MINOR_INTERVAL = 6.hours
  DIGEST_INTERVAL = 24.hours

  def initialize(alert, current_price, options = {})
    @alert = alert
    @current_price = current_price
    @historical_data = options[:historical_data] || []
    @user_preferences = options[:user_preferences] || {}
  end

  # Main method to determine if alert should be sent
  def should_send_alert?
    return false unless valid_alert?
    return false if spam_prevention_active?
    return false if recently_sent_similar_alert?
    
    price_drop_significant? || urgent_booking_window?
  end

  # Determine the urgency level of the alert
  def alert_urgency
    return :urgent if urgent_booking_window? && price_drop_significant?
    return :urgent if price_drop_percentage >= URGENT_THRESHOLD
    return :significant if price_drop_percentage >= SIGNIFICANT_THRESHOLD
    return :minor if price_drop_percentage >= MINOR_THRESHOLD
    :none
  end

  # Generate smart content based on context
  def generate_alert_content
    {
      urgency: alert_urgency,
      title: generate_title,
      body: generate_body,
      call_to_action: generate_call_to_action,
      context: generate_context,
      confidence_score: calculate_confidence_score,
      booking_recommendation: generate_booking_recommendation
    }
  end

  # Determine optimal delivery timing
  def optimal_delivery_time
    case alert_urgency
    when :urgent
      Time.current # Immediate delivery
    when :significant
      # Deliver within 30 minutes, but avoid late night/early morning
      if current_hour.between?(22, 6)
        next_morning
      else
        Time.current + 15.minutes
      end
    when :minor
      # Deliver during business hours
      if current_hour.between?(9, 17)
        Time.current + 1.hour
      else
        next_business_day
      end
    else
      nil # Don't deliver
    end
  end

  # Generate personalized subject line
  def generate_title
    savings_amount = price_drop_amount
    savings_percentage = price_drop_percentage
    
    case alert_urgency
    when :urgent
      "🚨 URGENT: #{alert.route_description} - Save $#{savings_amount} (#{savings_percentage}% off)"
    when :significant
      "🎉 Great Deal: #{alert.route_description} - Save $#{savings_amount}"
    when :minor
      "💰 Price Drop: #{alert.route_description} - Save $#{savings_amount}"
    else
      "Price Update: #{alert.route_description}"
    end
  end

  # Generate detailed body content
  def generate_body
    base_content = {
      route: alert.route_description,
      original_price: alert.target_price,
      current_price: current_price,
      savings: {
        amount: price_drop_amount,
        percentage: price_drop_percentage
      },
      departure_date: alert.departure_date&.strftime('%B %d, %Y'),
      confidence: "#{(confidence_score * 100).round}% confidence"
    }

    # Add urgency-specific content
    case alert_urgency
    when :urgent
      base_content.merge(
        urgency_message: "This is a significant price drop! Book quickly as this price may not last long.",
        time_sensitivity: "Price typically increases closer to departure",
        recommendation: "Consider booking immediately"
      )
    when :significant
      base_content.merge(
        urgency_message: "This is a good deal worth considering.",
        time_sensitivity: "Price may continue to fluctuate",
        recommendation: "Review and book within 24 hours"
      )
    when :minor
      base_content.merge(
        urgency_message: "Small price drop detected.",
        time_sensitivity: "Price may continue to drop",
        recommendation: "Monitor for better deals"
      )
    end
  end

  # Generate call-to-action based on urgency
  def generate_call_to_action
    case alert_urgency
    when :urgent
      {
        primary: "Book Now - Limited Time",
        secondary: "View Details",
        urgency: "This deal may not last long!"
      }
    when :significant
      {
        primary: "Check This Deal",
        secondary: "Set New Alert",
        urgency: "Good savings opportunity"
      }
    when :minor
      {
        primary: "View Price History",
        secondary: "Adjust Alert Settings",
        urgency: "Monitor for better deals"
      }
    else
      {
        primary: "View Details",
        secondary: "Manage Alerts",
        urgency: nil
      }
    end
  end

  # Generate contextual information
  def generate_context
    context = {
      price_trend: analyze_price_trend,
      historical_low: find_historical_low,
      booking_window: calculate_booking_window,
      route_popularity: assess_route_popularity,
      seasonal_factors: analyze_seasonal_factors
    }

    # Add wedding-specific context if applicable
    if alert.wedding_mode?
      context[:wedding_context] = {
        wedding_date: alert.wedding_date&.strftime('%B %d, %Y'),
        guest_count: alert.guest_count,
        urgency: wedding_urgency_level
      }
    end

    context
  end

  # Calculate confidence score for the alert
  def calculate_confidence_score
    score = 0.5 # Base score

    # Price drop significance
    score += price_drop_percentage * 2 # Up to 0.2 points for price drop

    # Data quality
    score += 0.1 if historical_data.present?
    score += 0.1 if alert.alert_quality_score.present?

    # Urgency factors
    score += 0.1 if urgent_booking_window?
    score += 0.1 if price_trend_positive?

    # User engagement
    score += 0.1 if user_has_high_engagement?

    # Ensure score is between 0 and 1
    [score, 1.0].min
  end

  # Generate booking recommendation
  def generate_booking_recommendation
    case alert_urgency
    when :urgent
      {
        action: "book_immediately",
        reason: "Significant price drop with limited time",
        confidence: "high",
        alternatives: ["Check multiple booking sites", "Consider flexible dates"]
      }
    when :significant
      {
        action: "book_soon",
        reason: "Good deal worth considering",
        confidence: "medium",
        alternatives: ["Wait for better deal", "Set up additional alerts"]
      }
    when :minor
      {
        action: "monitor",
        reason: "Small drop, may continue declining",
        confidence: "low",
        alternatives: ["Adjust alert settings", "Wait for better deal"]
      }
    else
      {
        action: "no_action",
        reason: "Price drop not significant enough",
        confidence: "very_low",
        alternatives: ["Adjust alert thresholds", "Monitor price trends"]
      }
    end
  end

  private

  def valid_alert?
    alert.present? && current_price.present? && current_price > 0
  end

  def spam_prevention_active?
    return false unless alert.notification_history.present?
    
    recent_notifications = alert.notification_history
                               .select { |n| n['timestamp'] && Time.parse(n['timestamp']) > 1.hour.ago }
                               .count
    
    recent_notifications >= 3 # Max 3 notifications per hour
  end

  def recently_sent_similar_alert?
    return false unless alert.notification_history.present?
    
    recent_alerts = alert.notification_history
                        .select { |n| n['timestamp'] && Time.parse(n['timestamp']) > 2.hours.ago }
    
    recent_alerts.any? do |notification|
      notification['content']&.include?(alert.route_description) &&
      notification['success'] == true
    end
  end

  def price_drop_significant?
    price_drop_percentage >= MINOR_THRESHOLD
  end

  def urgent_booking_window?
    return false unless alert.departure_date
    
    days_until_departure = (alert.departure_date - Date.current).to_i
    days_until_departure <= 30 # Within 30 days
  end

  def price_drop_percentage
    return 0 unless alert.target_price && current_price
    
    ((alert.target_price - current_price) / alert.target_price * 100).round(2)
  end

  def price_drop_amount
    return 0 unless alert.target_price && current_price
    
    alert.target_price - current_price
  end

  def current_hour
    Time.current.hour
  end

  def next_morning
    Time.current.beginning_of_day + 8.hours
  end

  def next_business_day
    next_day = Time.current + 1.day
    next_day.beginning_of_day + 9.hours
  end

  def analyze_price_trend
    return "insufficient_data" if historical_data.length < 3
    
    recent_prices = historical_data.last(7).map { |d| d[:price] }
    trend = recent_prices.each_cons(2).map { |a, b| b <=> a }.sum
    
    case trend
    when -6..-1 then "declining"
    when 0 then "stable"
    when 1..6 then "rising"
    else "volatile"
    end
  end

  def find_historical_low
    return nil if historical_data.empty?
    
    historical_data.min_by { |d| d[:price] }[:price]
  end

  def calculate_booking_window
    return nil unless alert.departure_date
    
    days_until_departure = (alert.departure_date - Date.current).to_i
    
    case days_until_departure
    when 0..7 then "last_minute"
    when 8..30 then "short_term"
    when 31..90 then "medium_term"
    else "long_term"
    end
  end

  def assess_route_popularity
    # This would integrate with actual data
    # For now, return a placeholder
    "moderate"
  end

  def analyze_seasonal_factors
    return {} unless alert.departure_date
    
    month = alert.departure_date.month
    
    case month
    when 12, 1, 2 then { season: "winter", factor: "high_demand" }
    when 6, 7, 8 then { season: "summer", factor: "peak_travel" }
    when 3, 4, 5 then { season: "spring", factor: "moderate_demand" }
    else { season: "fall", factor: "moderate_demand" }
    end
  end

  def wedding_urgency_level
    return "low" unless alert.wedding_date
    
    days_until_wedding = (alert.wedding_date - Date.current).to_i
    
    case days_until_wedding
    when 0..30 then "critical"
    when 31..90 then "high"
    when 91..180 then "medium"
    else "low"
    end
  end

  def price_trend_positive?
    analyze_price_trend == "declining"
  end

  def user_has_high_engagement?
    # This would check user's historical engagement with alerts
    # For now, return a placeholder
    true
  end

  def confidence_score
    calculate_confidence_score
  end
end
