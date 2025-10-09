class PriceBreakDetectionService
  include ActiveModel::Validations

  attr_reader :errors, :detections, :false_positives_prevented

  def initialize
    @errors = []
    @detections = 0
    @false_positives_prevented = 0
  end

  # Main detection method
  def detect_price_breaks(filter, current_prices)
    @errors = []
    @detections = 0
    @false_positives_prevented = 0

    return { success: false, error: 'No current prices provided' } if current_prices.empty?

    # Get historical context for this route
    historical_context = get_historical_context(filter)
    
    # Analyze each current price
    price_breaks = []
    
    current_prices.each do |price_data|
      begin
        detection_result = analyze_single_price(filter, price_data, historical_context)
        
        if detection_result[:is_price_break]
          price_breaks << detection_result
          @detections += 1
        elsif detection_result[:false_positive_prevented]
          @false_positives_prevented += 1
        end
        
      rescue => e
        @errors << "Error analyzing price: #{e.message}"
        Rails.logger.error "Price break detection error: #{e.message}"
      end
    end

    # Sort by confidence score and return best matches
    price_breaks.sort_by { |break_data| -break_data[:confidence_score] }

    {
      success: @errors.empty?,
      price_breaks: price_breaks,
      detections: @detections,
      false_positives_prevented: @false_positives_prevented,
      errors: @errors
    }
  end

  # Analyze a single price for potential breaks
  def analyze_single_price(filter, price_data, historical_context)
    current_price = extract_price(price_data)
    return invalid_price_result('No valid price found') unless current_price

    # Basic price validation
    return invalid_price_result('Price below minimum threshold') if current_price < 10
    return invalid_price_result('Price above maximum threshold') if current_price > 50000

    # Check against filter criteria
    unless matches_filter_criteria?(filter, price_data)
      return invalid_price_result('Does not match filter criteria')
    end

    # Apply spam prevention
    spam_prevention = SpamPreventionService.new
    spam_result = spam_prevention.prevent_spam(filter, price_data, historical_context)
    
    if spam_result[:is_spam]
      return {
        is_price_break: false,
        current_price: current_price,
        false_positive_prevented: true,
        false_positive_reasons: spam_result[:spam_reasons],
        spam_prevention_applied: true
      }
    end

    # Calculate price drop metrics
    price_metrics = calculate_price_metrics(filter, current_price, historical_context)
    
    # Apply spam prevention confidence penalty
    if spam_result[:confidence_penalty] > 0
      price_metrics[:confidence_score] = [price_metrics[:confidence_score] - spam_result[:confidence_penalty], 0.0].max
    end
    
    # Determine if this is a meaningful price break
    is_meaningful_break = determine_meaningful_break(filter, price_metrics, historical_context)
    
    if is_meaningful_break
      {
        is_price_break: true,
        current_price: current_price,
        target_price: filter.target_price,
        price_drop_amount: price_metrics[:drop_amount],
        price_drop_percentage: price_metrics[:drop_percentage],
        confidence_score: price_metrics[:confidence_score],
        historical_context: historical_context,
        price_data: price_data,
        detection_reasons: price_metrics[:detection_reasons],
        spam_prevention_applied: true,
        spam_confidence_penalty: spam_result[:confidence_penalty],
        false_positive_prevented: false
      }
    else
      {
        is_price_break: false,
        current_price: current_price,
        false_positive_prevented: price_metrics[:false_positive_reasons].any?,
        false_positive_reasons: price_metrics[:false_positive_reasons],
        price_metrics: price_metrics,
        spam_prevention_applied: true
      }
    end
  end

  # Get historical context for a route
  def get_historical_context(filter)
    route = filter.route_description
    
    # Use performance optimization service for caching
    performance_service = PerformanceOptimizationService.new
    
    performance_service.cache_route_analysis(route) do
      # Get recent price history (last 30 days)
      recent_prices = FlightPriceHistory.by_route(route)
                                      .where('timestamp >= ?', 30.days.ago)
                                      .valid_prices
                                      .order(:timestamp)
      
      # Get price statistics
      price_values = recent_prices.pluck(:price)
      
      context = {
        route: route,
        recent_prices: price_values,
        price_count: price_values.length,
        average_price: calculate_average_price(price_values),
        median_price: calculate_median_price(price_values),
        min_price: price_values.min,
        max_price: price_values.max,
        price_volatility: calculate_price_volatility(price_values),
        trend_direction: calculate_price_trend(price_values),
        recent_drops: count_recent_drops(price_values),
        data_quality_score: calculate_data_quality_score(recent_prices)
      }
      
      # Add seasonal context if available
      context[:seasonal_context] = get_seasonal_context(route, filter.departure_dates_array.first)
      
      context
    end
  end

  # Calculate comprehensive price metrics
  def calculate_price_metrics(filter, current_price, historical_context)
    target_price = filter.target_price
    recent_prices = historical_context[:recent_prices]
    
    # Basic drop calculations
    drop_amount = target_price - current_price
    drop_percentage = (drop_amount / target_price * 100).round(2)
    
    # Historical comparison
    historical_avg = historical_context[:average_price]
    historical_median = historical_context[:median_price]
    
    # Calculate relative metrics
    vs_historical_avg = historical_avg ? ((historical_avg - current_price) / historical_avg * 100).round(2) : 0
    vs_historical_median = historical_median ? ((historical_median - current_price) / historical_median * 100).round(2) : 0
    
    # Calculate confidence score
    confidence_score = calculate_confidence_score(
      current_price, 
      target_price, 
      historical_context, 
      drop_percentage
    )
    
    # Determine detection reasons
    detection_reasons = []
    false_positive_reasons = []
    
    # Positive indicators
    if drop_percentage >= 10
      detection_reasons << "Significant price drop (#{drop_percentage}%)"
    end
    
    if vs_historical_avg >= 15
      detection_reasons << "Well below historical average (#{vs_historical_avg}%)"
    end
    
    if current_price <= historical_context[:min_price] * 1.1
      detection_reasons << "Near historical minimum"
    end
    
    # Negative indicators (false positive prevention)
    if historical_context[:price_volatility] > 50
      false_positive_reasons << "High price volatility (#{historical_context[:price_volatility]}%)"
    end
    
    if recent_prices.length < 5
      false_positive_reasons << "Insufficient historical data"
    end
    
    if historical_context[:recent_drops] > 3
      false_positive_reasons << "Too many recent drops (#{historical_context[:recent_drops]})"
    end
    
    # Check for suspicious patterns
    if is_suspicious_price_pattern?(current_price, recent_prices)
      false_positive_reasons << "Suspicious price pattern detected"
    end
    
    {
      drop_amount: drop_amount,
      drop_percentage: drop_percentage,
      vs_historical_avg: vs_historical_avg,
      vs_historical_median: vs_historical_median,
      confidence_score: confidence_score,
      detection_reasons: detection_reasons,
      false_positive_reasons: false_positive_reasons
    }
  end

  # Determine if this is a meaningful price break
  def determine_meaningful_break(filter, price_metrics, historical_context)
    # Must be below target price
    return false if price_metrics[:drop_percentage] <= 0
    
    # Must meet minimum drop threshold
    min_drop_percentage = filter.alert_settings&.dig('min_drop_percentage') || 5.0
    return false if price_metrics[:drop_percentage] < min_drop_percentage
    
    # Must have sufficient confidence
    min_confidence = filter.alert_settings&.dig('min_confidence') || 0.6
    return false if price_metrics[:confidence_score] < min_confidence
    
    # Must not be flagged as false positive
    return false if price_metrics[:false_positive_reasons].any?
    
    # Additional quality checks
    return false unless passes_quality_checks(filter, price_metrics, historical_context)
    
    true
  end

  # Calculate confidence score for a price break
  def calculate_confidence_score(current_price, target_price, historical_context, drop_percentage)
    score = 0.5 # Base score
    
    # Higher confidence for larger drops
    score += [drop_percentage / 100.0, 0.3].min
    
    # Higher confidence for prices well below historical average
    if historical_context[:average_price] && current_price < historical_context[:average_price]
      avg_discount = (historical_context[:average_price] - current_price) / historical_context[:average_price]
      score += [avg_discount, 0.2].min
    end
    
    # Higher confidence for stable price history
    if historical_context[:price_volatility] < 20
      score += 0.1
    elsif historical_context[:price_volatility] > 50
      score -= 0.2
    end
    
    # Higher confidence for more historical data
    if historical_context[:price_count] >= 20
      score += 0.1
    elsif historical_context[:price_count] < 5
      score -= 0.3
    end
    
    # Higher confidence for positive trend (prices generally going up)
    if historical_context[:trend_direction] == 'increasing'
      score += 0.1
    end
    
    # Adjust for data quality
    score *= historical_context[:data_quality_score]
    
    # Cap at 1.0
    [score, 1.0].min
  end

  # Check if price passes quality checks
  def passes_quality_checks(filter, price_metrics, historical_context)
    # Check for minimum data quality
    return false if historical_context[:data_quality_score] < 0.5
    
    # Check for reasonable price range
    return false if price_metrics[:drop_percentage] > 80 # Suspiciously large drop
    
    # Check for recent activity (not too many recent drops)
    return false if historical_context[:recent_drops] > 5
    
    # Check for seasonal appropriateness
    if historical_context[:seasonal_context]
      seasonal_factor = historical_context[:seasonal_context][:price_factor]
      return false if seasonal_factor && current_price < historical_context[:average_price] * seasonal_factor
    end
    
    true
  end

  # Check for suspicious price patterns
  def is_suspicious_price_pattern?(current_price, recent_prices)
    return false if recent_prices.length < 3
    
    # Check for prices that are too good to be true
    if current_price < recent_prices.min * 0.5
      return true
    end
    
    # Check for round numbers (often fake)
    if current_price % 100 == 0 && current_price < 1000
      return true
    end
    
    # Check for prices that are exactly half of common prices
    common_prices = [299, 399, 499, 599, 699, 799, 899, 999]
    if common_prices.include?(current_price * 2)
      return true
    end
    
    false
  end

  # Get seasonal context for a route
  def get_seasonal_context(route, departure_date)
    return nil unless departure_date
    
    # This would typically use historical data to determine seasonal patterns
    # For now, return basic seasonal factors
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

  # Helper methods for calculations
  def extract_price(price_data)
    price_data[:price] || price_data['price'] || price_data[:amount] || price_data['amount']
  end

  def calculate_average_price(prices)
    return 0 if prices.empty?
    prices.sum.to_f / prices.length
  end

  def calculate_median_price(prices)
    return 0 if prices.empty?
    sorted_prices = prices.sort
    mid = sorted_prices.length / 2
    sorted_prices.length.odd? ? sorted_prices[mid] : (sorted_prices[mid - 1] + sorted_prices[mid]) / 2.0
  end

  def calculate_price_volatility(prices)
    return 0 if prices.length < 2
    
    mean = calculate_average_price(prices)
    variance = prices.sum { |price| (price - mean) ** 2 } / prices.length
    standard_deviation = Math.sqrt(variance)
    
    (standard_deviation / mean * 100).round(2)
  end

  def calculate_price_trend(prices)
    return 'unknown' if prices.length < 3
    
    # Simple linear trend calculation
    n = prices.length
    sum_x = (0...n).sum
    sum_y = prices.sum
    sum_xy = (0...n).sum { |i| i * prices[i] }
    sum_x2 = (0...n).sum { |i| i * i }
    
    slope = (n * sum_xy - sum_x * sum_y).to_f / (n * sum_x2 - sum_x * sum_x)
    
    case
    when slope > 0.1
      'increasing'
    when slope < -0.1
      'decreasing'
    else
      'stable'
    end
  end

  def count_recent_drops(prices)
    return 0 if prices.length < 2
    
    drops = 0
    (1...prices.length).each do |i|
      drops += 1 if prices[i] < prices[i - 1]
    end
    
    drops
  end

  def calculate_data_quality_score(price_records)
    return 0.5 if price_records.empty?
    
    # Calculate based on validation status and recency
    valid_count = price_records.where(price_validation_status: 'valid').count
    recent_count = price_records.where('timestamp >= ?', 7.days.ago).count
    
    quality_score = (valid_count.to_f / price_records.count) * 0.7
    quality_score += (recent_count.to_f / price_records.count) * 0.3
    
    [quality_score, 1.0].min
  end

  def matches_filter_criteria?(filter, price_data)
    # Check cabin class
    if filter.cabin_class != 'any'
      flight_cabin = price_data[:cabin_class] || price_data['cabin_class']
      return false if flight_cabin && flight_cabin != filter.cabin_class
    end
    
    # Check stops
    if filter.max_stops != 'any'
      flight_stops = price_data[:stops] || price_data['stops'] || 0
      case filter.max_stops
      when 'nonstop'
        return false if flight_stops > 0
      when '1-stop'
        return false if flight_stops > 1
      when '2+'
        # Allow any number of stops
      end
    end
    
    # Check airline preferences
    if filter.airline_preferences.any?
      flight_airline = price_data[:airline] || price_data['airline']
      return false if flight_airline && !filter.airline_preferences.include?(flight_airline)
    end
    
    true
  end

  def invalid_price_result(reason)
    {
      is_price_break: false,
      false_positive_prevented: true,
      false_positive_reasons: [reason],
      price_metrics: {}
    }
  end

  # Class method to get detection statistics
  def self.detection_stats
    {
      total_detections: FlightAlert.where(status: 'triggered').count,
      recent_detections: FlightAlert.where(status: 'triggered')
                                  .where('created_at >= ?', 24.hours.ago).count,
      average_confidence: FlightAlert.where(status: 'triggered')
                                   .where.not(alert_quality_score: nil)
                                   .average(:alert_quality_score) || 0,
      false_positive_rate: calculate_false_positive_rate
    }
  end

  def self.calculate_false_positive_rate
    # This would typically be calculated based on user feedback
    # For now, return a placeholder
    0.05 # 5% false positive rate
  end
end
