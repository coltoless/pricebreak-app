class SpamPreventionService
  include ActiveModel::Validations

  attr_reader :errors, :filtered_count, :spam_detected

  def initialize
    @errors = []
    @filtered_count = 0
    @spam_detected = 0
  end

  # Main spam prevention method
  def prevent_spam(filter, price_data, historical_context = nil)
    @errors = []
    @filtered_count = 0
    @spam_detected = 0

    return { success: false, error: 'No price data provided' } if price_data.blank?

    # Get historical context if not provided
    historical_context ||= get_historical_context(filter)

    # Apply spam prevention filters
    spam_checks = [
      :check_price_realism,
      :check_volatility_threshold,
      :check_frequency_limits,
      :check_pattern_anomalies,
      :check_data_quality,
      :check_seasonal_appropriateness,
      :check_provider_reliability,
      :check_user_alert_history
    ]

    spam_reasons = []
    confidence_penalty = 0.0

    spam_checks.each do |check_method|
      begin
        result = send(check_method, filter, price_data, historical_context)
        
        if result[:is_spam]
          spam_reasons.concat(result[:reasons])
          confidence_penalty += result[:penalty] || 0.1
          @spam_detected += 1
        end
        
        @filtered_count += 1
        
      rescue => e
        @errors << "Error in #{check_method}: #{e.message}"
        Rails.logger.error "Spam prevention error in #{check_method}: #{e.message}"
      end
    end

    # Determine if this is spam
    is_spam = spam_reasons.any?
    final_confidence = [1.0 - confidence_penalty, 0.0].max

    {
      success: @errors.empty?,
      is_spam: is_spam,
      spam_reasons: spam_reasons,
      confidence_penalty: confidence_penalty,
      final_confidence: final_confidence,
      filtered_count: @filtered_count,
      spam_detected: @spam_detected,
      errors: @errors
    }
  end

  # Check if price is realistic
  def check_price_realism(filter, price_data, historical_context)
    current_price = extract_price(price_data)
    return { is_spam: false } unless current_price

    reasons = []
    penalty = 0.0

    # Check for extremely low prices
    if current_price < 25
      reasons << "Price suspiciously low ($#{current_price})"
      penalty += 0.3
    end

    # Check for extremely high prices
    if current_price > 20000
      reasons << "Price suspiciously high ($#{current_price})"
      penalty += 0.2
    end

    # Check against historical minimum
    if historical_context[:min_price] && current_price < historical_context[:min_price] * 0.3
      reasons << "Price far below historical minimum"
      penalty += 0.4
    end

    # Check for round number prices (often fake)
    if current_price % 100 == 0 && current_price < 1000
      reasons << "Suspicious round number price"
      penalty += 0.1
    end

    # Check for prices that are exactly half of common prices
    common_prices = [299, 399, 499, 599, 699, 799, 899, 999, 1299, 1499, 1999]
    if common_prices.include?(current_price * 2)
      reasons << "Price appears to be half of common price point"
      penalty += 0.2
    end

    {
      is_spam: reasons.any?,
      reasons: reasons,
      penalty: penalty
    }
  end

  # Check volatility threshold
  def check_volatility_threshold(filter, price_data, historical_context)
    return { is_spam: false } unless historical_context[:price_volatility]

    reasons = []
    penalty = 0.0

    volatility = historical_context[:price_volatility]
    
    # High volatility can indicate unreliable pricing
    if volatility > 80
      reasons << "Extremely high price volatility (#{volatility}%)"
      penalty += 0.3
    elsif volatility > 50
      reasons << "High price volatility (#{volatility}%)"
      penalty += 0.1
    end

    # Check for sudden price changes
    if historical_context[:recent_prices].length >= 3
      recent_avg = historical_context[:recent_prices].last(3).sum.to_f / 3
      current_price = extract_price(price_data)
      
      if current_price && recent_avg > 0
        change_percentage = ((recent_avg - current_price) / recent_avg * 100).abs
        
        if change_percentage > 50
          reasons << "Sudden large price change (#{change_percentage.round}%)"
          penalty += 0.4
        elsif change_percentage > 30
          reasons << "Significant price change (#{change_percentage.round}%)"
          penalty += 0.2
        end
      end
    end

    {
      is_spam: reasons.any?,
      reasons: reasons,
      penalty: penalty
    }
  end

  # Check frequency limits
  def check_frequency_limits(filter, price_data, historical_context)
    reasons = []
    penalty = 0.0

    # Check for too many recent alerts for this filter
    recent_alerts = FlightAlert.where(flight_filter: filter)
                              .where('created_at >= ?', 24.hours.ago)
                              .count

    if recent_alerts >= 5
      reasons << "Too many recent alerts (#{recent_alerts} in 24h)"
      penalty += 0.5
    elsif recent_alerts >= 3
      reasons << "Multiple recent alerts (#{recent_alerts} in 24h)"
      penalty += 0.2
    end

    # Check for too many alerts for this route
    route_alerts = FlightAlert.joins(:flight_filter)
                             .where(flight_filters: { route_description: filter.route_description })
                             .where('created_at >= ?', 1.hour.ago)
                             .count

    if route_alerts >= 10
      reasons << "Too many alerts for this route (#{route_alerts} in 1h)"
      penalty += 0.3
    end

    {
      is_spam: reasons.any?,
      reasons: reasons,
      penalty: penalty
    }
  end

  # Check for pattern anomalies
  def check_pattern_anomalies(filter, price_data, historical_context)
    reasons = []
    penalty = 0.0

    current_price = extract_price(price_data)
    return { is_spam: false } unless current_price

    # Check for suspicious price patterns
    if historical_context[:recent_prices].length >= 5
      recent_prices = historical_context[:recent_prices].last(5)
      
      # Check for alternating high/low pattern
      if alternating_pattern?(recent_prices)
        reasons << "Suspicious alternating price pattern"
        penalty += 0.3
      end
      
      # Check for stair-step pattern
      if stair_step_pattern?(recent_prices)
        reasons << "Suspicious stair-step price pattern"
        penalty += 0.2
      end
      
      # Check for prices that are exactly multiples of each other
      if multiple_pattern?(recent_prices)
        reasons << "Suspicious multiple price pattern"
        penalty += 0.2
      end
    end

    # Check for prices that are too close to common psychological price points
    psychological_prices = [99, 199, 299, 399, 499, 599, 699, 799, 899, 999]
    if psychological_prices.include?(current_price)
      reasons << "Price at psychological price point (may be fake)"
      penalty += 0.1
    end

    {
      is_spam: reasons.any?,
      reasons: reasons,
      penalty: penalty
    }
  end

  # Check data quality
  def check_data_quality(filter, price_data, historical_context)
    reasons = []
    penalty = 0.0

    # Check for missing critical data
    if price_data[:airline].blank? && price_data['airline'].blank?
      reasons << "Missing airline information"
      penalty += 0.2
    end

    if price_data[:flight_number].blank? && price_data['flight_number'].blank?
      reasons << "Missing flight number"
      penalty += 0.1
    end

    if price_data[:departure_time].blank? && price_data['departure_time'].blank?
      reasons << "Missing departure time"
      penalty += 0.1
    end

    # Check for invalid data formats
    if price_data[:price] && !price_data[:price].is_a?(Numeric)
      reasons << "Invalid price format"
      penalty += 0.3
    end

    # Check data quality score
    if historical_context[:data_quality_score] < 0.5
      reasons << "Low data quality score (#{(historical_context[:data_quality_score] * 100).round}%)"
      penalty += 0.2
    end

    {
      is_spam: reasons.any?,
      reasons: reasons,
      penalty: penalty
    }
  end

  # Check seasonal appropriateness
  def check_seasonal_appropriateness(filter, price_data, historical_context)
    return { is_spam: false } unless historical_context[:seasonal_context]

    reasons = []
    penalty = 0.0

    seasonal_context = historical_context[:seasonal_context]
    current_price = extract_price(price_data)
    
    return { is_spam: false } unless current_price

    # Check if price is appropriate for the season
    if seasonal_context[:demand_high] && current_price < historical_context[:average_price] * 0.7
      reasons << "Price too low for high-demand season"
      penalty += 0.3
    end

    # Check for prices that don't match seasonal patterns
    if seasonal_context[:price_factor] && current_price < historical_context[:average_price] * seasonal_context[:price_factor] * 0.5
      reasons << "Price doesn't match seasonal patterns"
      penalty += 0.2
    end

    {
      is_spam: reasons.any?,
      reasons: reasons,
      penalty: penalty
    }
  end

  # Check provider reliability
  def check_provider_reliability(filter, price_data, historical_context)
    reasons = []
    penalty = 0.0

    provider = price_data[:provider] || price_data['provider']
    return { is_spam: false } unless provider

    # Check provider reliability based on historical data
    provider_stats = get_provider_stats(provider)
    
    if provider_stats[:reliability_score] < 0.6
      reasons << "Low provider reliability (#{(provider_stats[:reliability_score] * 100).round}%)"
      penalty += 0.3
    end

    if provider_stats[:error_rate] > 0.2
      reasons << "High provider error rate (#{(provider_stats[:error_rate] * 100).round}%)"
      penalty += 0.2
    end

    # Check for providers known to have fake pricing
    unreliable_providers = ['fake_provider', 'test_provider'] # Add known unreliable providers
    if unreliable_providers.include?(provider)
      reasons << "Known unreliable provider"
      penalty += 0.5
    end

    {
      is_spam: reasons.any?,
      reasons: reasons,
      penalty: penalty
    }
  end

  # Check user alert history
  def check_user_alert_history(filter, price_data, historical_context)
    reasons = []
    penalty = 0.0

    # This would check the user's alert history to prevent spam
    # For now, we'll implement basic checks
    
    # Check if user has been getting too many alerts recently
    # This would require user association which is currently disabled
    
    # Check for similar alerts that were marked as spam
    similar_alerts = FlightAlert.joins(:flight_filter)
                               .where(flight_filters: { route_description: filter.route_description })
                               .where('created_at >= ?', 7.days.ago)
                               .where('alert_quality_score < ?', 0.3)
                               .count

    if similar_alerts >= 3
      reasons << "Multiple low-quality alerts for this route recently"
      penalty += 0.2
    end

    {
      is_spam: reasons.any?,
      reasons: reasons,
      penalty: penalty
    }
  end

  # Helper methods
  def get_historical_context(filter)
    route = filter.route_description
    
    recent_prices = FlightPriceHistory.by_route(route)
                                    .where('timestamp >= ?', 30.days.ago)
                                    .valid_prices
                                    .order(:timestamp)
    
    price_values = recent_prices.pluck(:price)
    
    {
      route: route,
      recent_prices: price_values,
      price_count: price_values.length,
      average_price: calculate_average_price(price_values),
      min_price: price_values.min,
      max_price: price_values.max,
      price_volatility: calculate_price_volatility(price_values),
      data_quality_score: calculate_data_quality_score(recent_prices),
      seasonal_context: get_seasonal_context(route, filter.departure_dates_array.first)
    }
  end

  def get_provider_stats(provider)
    # Get provider statistics from historical data
    provider_data = FlightProviderDatum.by_provider(provider)
                                     .where('data_timestamp >= ?', 30.days.ago)
    
    total_records = provider_data.count
    valid_records = provider_data.valid_data.count
    error_rate = total_records > 0 ? (total_records - valid_records).to_f / total_records : 0
    reliability_score = total_records > 0 ? valid_records.to_f / total_records : 0.5
    
    {
      total_records: total_records,
      valid_records: valid_records,
      error_rate: error_rate,
      reliability_score: reliability_score
    }
  end

  def extract_price(price_data)
    price_data[:price] || price_data['price'] || price_data[:amount] || price_data['amount']
  end

  def calculate_average_price(prices)
    return 0 if prices.empty?
    prices.sum.to_f / prices.length
  end

  def calculate_price_volatility(prices)
    return 0 if prices.length < 2
    
    mean = calculate_average_price(prices)
    variance = prices.sum { |price| (price - mean) ** 2 } / prices.length
    standard_deviation = Math.sqrt(variance)
    
    (standard_deviation / mean * 100).round(2)
  end

  def calculate_data_quality_score(price_records)
    return 0.5 if price_records.empty?
    
    valid_count = price_records.where(price_validation_status: 'valid').count
    recent_count = price_records.where('timestamp >= ?', 7.days.ago).count
    
    quality_score = (valid_count.to_f / price_records.count) * 0.7
    quality_score += (recent_count.to_f / price_records.count) * 0.3
    
    [quality_score, 1.0].min
  end

  def get_seasonal_context(route, departure_date)
    return nil unless departure_date
    
    month = departure_date.month
    
    case month
    when 12, 1, 2 # Winter
      { season: 'winter', price_factor: 1.2, demand_high: true }
    when 6, 7, 8 # Summer
      { season: 'summer', price_factor: 1.3, demand_high: true }
    when 3, 4, 5 # Spring
      { season: 'spring', price_factor: 0.9, demand_high: false }
    when 9, 10, 11 # Fall
      { season: 'fall', price_factor: 0.8, demand_high: false }
    else
      { season: 'unknown', price_factor: 1.0, demand_high: false }
    end
  end

  # Pattern detection methods
  def alternating_pattern?(prices)
    return false if prices.length < 4
    
    (0...prices.length - 1).each do |i|
      if i % 2 == 0
        return false unless prices[i] > prices[i + 1]
      else
        return false unless prices[i] < prices[i + 1]
      end
    end
    
    true
  end

  def stair_step_pattern?(prices)
    return false if prices.length < 3
    
    # Check if prices are consistently increasing or decreasing
    increasing = true
    decreasing = true
    
    (0...prices.length - 1).each do |i|
      if prices[i] >= prices[i + 1]
        increasing = false
      end
      if prices[i] <= prices[i + 1]
        decreasing = false
      end
    end
    
    increasing || decreasing
  end

  def multiple_pattern?(prices)
    return false if prices.length < 3
    
    # Check if prices are multiples of each other
    base_price = prices.first
    return false if base_price <= 0
    
    prices[1..-1].each do |price|
      if price % base_price != 0 && base_price % price != 0
        return false
      end
    end
    
    true
  end

  # Class method to get spam prevention statistics
  def self.spam_prevention_stats
    {
      total_checks: FlightAlert.count,
      spam_detected: FlightAlert.where('alert_quality_score < ?', 0.3).count,
      false_positive_rate: calculate_false_positive_rate,
      average_confidence: FlightAlert.where.not(alert_quality_score: nil)
                                   .average(:alert_quality_score) || 0
    }
  end

  def self.calculate_false_positive_rate
    # This would typically be calculated based on user feedback
    # For now, return a placeholder
    0.02 # 2% false positive rate
  end
end



