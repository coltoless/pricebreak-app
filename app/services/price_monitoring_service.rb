class PriceMonitoringService
  include ActiveModel::Validations

  attr_reader :errors, :monitored_count, :alerts_triggered, :price_breaks_detected

  def initialize
    @errors = []
    @monitored_count = 0
    @alerts_triggered = 0
    @price_breaks_detected = 0
  end

  # Main monitoring method - checks all active filters
  def monitor_all_filters
    @errors = []
    @monitored_count = 0
    @alerts_triggered = 0
    @price_breaks_detected = 0

    # Use performance optimization service
    performance_service = PerformanceOptimizationService.new
    
    performance_service.optimize_performance(:monitor_all_filters) do
      # Get all active filters that need checking
      active_filters = FlightFilter.active
                                  .where('next_check_scheduled <= ?', Time.current)
                                  .order(:priority_score)

      Rails.logger.info "Starting price monitoring for #{active_filters.count} filters"

      # Process filters in batches for better performance
      performance_service.batch_process_filters(active_filters) do |filter|
        begin
          monitor_single_filter(filter)
          @monitored_count += 1
        rescue => e
          @errors << "Error monitoring filter #{filter.id}: #{e.message}"
          Rails.logger.error "Price monitoring error for filter #{filter.id}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
        end
      end
    end

    {
      success: @errors.empty?,
      monitored_count: @monitored_count,
      alerts_triggered: @alerts_triggered,
      price_breaks_detected: @price_breaks_detected,
      errors: @errors
    }
  end

  # Monitor a single filter
  def monitor_single_filter(filter)
    return unless filter.is_active?

    Rails.logger.debug "Monitoring filter #{filter.id}: #{filter.route_description}"

    # Get current prices for this filter's criteria
    current_prices = fetch_current_prices(filter)
    
    if current_prices.empty?
      Rails.logger.warn "No current prices found for filter #{filter.id}"
      schedule_next_check(filter, :no_data)
      return
    end

    # Analyze prices and detect breaks
    price_analysis = analyze_prices(filter, current_prices)
    
    # Check for price breaks and trigger alerts
    if price_analysis[:price_break_detected]
      @price_breaks_detected += 1
      trigger_price_break_alert(filter, price_analysis)
    end

    # Update filter's last checked time and schedule next check
    update_filter_check_time(filter, price_analysis)
    
    # Update price history
    store_price_history(filter, current_prices)
  end

  # Fetch current prices for a filter
  def fetch_current_prices(filter)
    search_params = build_search_params(filter)
    
    # Use the flight aggregator service to get current prices
    aggregator = FlightApis::AggregatorService.new
    search_result = aggregator.search_all(search_params)
    
    if search_result[:success]
      search_result[:results] || []
    else
      Rails.logger.error "Failed to fetch prices for filter #{filter.id}: #{search_result[:errors]}"
      []
    end
  end

  # Analyze prices and detect meaningful breaks
  def analyze_prices(filter, current_prices)
    # Use the enhanced price break detection service
    detection_service = PriceBreakDetectionService.new
    detection_result = detection_service.detect_price_breaks(filter, current_prices)
    
    if detection_result[:success] && detection_result[:price_breaks].any?
      # Get the best price break (highest confidence)
      best_break = detection_result[:price_breaks].first
      
      {
        price_break_detected: true,
        best_price: best_break[:current_price],
        best_match: best_break[:price_data],
        price_drop_percentage: best_break[:price_drop_percentage],
        confidence_score: best_break[:confidence_score],
        analysis_details: {
          detection_reasons: best_break[:detection_reasons],
          historical_context: best_break[:historical_context],
          total_matches: current_prices.length,
          quality_filters_applied: true
        }
      }
    else
      # No meaningful price breaks detected
      {
        price_break_detected: false,
        best_price: nil,
        price_drop_percentage: 0,
        confidence_score: 0,
        analysis_details: { 
          reason: 'no_meaningful_breaks',
          false_positives_prevented: detection_result[:false_positives_prevented],
          errors: detection_result[:errors]
        }
      }
    end
  end

  # Find the best price match for a filter
  def find_best_price_match(filter, prices)
    return nil if prices.empty?

    # Filter prices by basic criteria
    matching_prices = prices.select do |price|
      matches_basic_criteria?(filter, price)
    end

    return nil if matching_prices.empty?

    # Sort by price and return the best match
    best_match = matching_prices.min_by { |p| p[:price] || p['price'] || Float::INFINITY }
    
    # Normalize the price data
    {
      price: best_match[:price] || best_match['price'],
      provider: best_match[:provider] || best_match['provider'],
      airline: best_match[:airline] || best_match['airline'],
      flight_number: best_match[:flight_number] || best_match['flight_number'],
      stops: best_match[:stops] || best_match['stops'] || 0,
      departure_time: best_match[:departure_time] || best_match['departure_time'],
      arrival_time: best_match[:arrival_time] || best_match['arrival_time'],
      cabin_class: best_match[:cabin_class] || best_match['cabin_class'],
      booking_url: best_match[:booking_url] || best_match['booking_url'],
      raw_data: best_match
    }
  end

  # Check if a price matches basic filter criteria
  def matches_basic_criteria?(filter, price)
    price_value = price[:price] || price['price']
    return false unless price_value.is_a?(Numeric)
    
    # Check price range
    return false if price_value < filter.min_price
    return false if price_value > filter.max_price
    
    # Check cabin class if specified
    if filter.cabin_class != 'any'
      flight_cabin = price[:cabin_class] || price['cabin_class']
      return false if flight_cabin && flight_cabin != filter.cabin_class
    end
    
    # Check stops if specified
    if filter.max_stops != 'any'
      flight_stops = price[:stops] || price['stops'] || 0
      case filter.max_stops
      when 'nonstop'
        return false if flight_stops > 0
      when '1-stop'
        return false if flight_stops > 1
      when '2+'
        # Allow any number of stops
      end
    end
    
    true
  end

  # Calculate price drop percentage
  def calculate_price_drop_percentage(target_price, current_price)
    return 0 if target_price <= 0 || current_price <= 0
    
    ((target_price - current_price) / target_price * 100).round(2)
  end

  # Detect if this is a meaningful price break
  def detect_meaningful_price_break(filter, current_price, price_drop_percentage, best_match)
    # Must be below target price
    return false if current_price >= filter.target_price
    
    # Must meet minimum drop percentage threshold
    min_drop_percentage = filter.alert_settings&.dig('min_drop_percentage') || 5.0
    return false if price_drop_percentage < min_drop_percentage
    
    # Check for spam prevention
    return false if is_spam_price?(filter, current_price, best_match)
    
    # Check if this is a significant enough change from recent prices
    return false unless is_significant_price_change?(filter, current_price)
    
    true
  end

  # Check if this might be spam/fake pricing
  def is_spam_price?(filter, current_price, best_match)
    # Check for suspiciously low prices
    if current_price < 50 # Less than $50
      return true
    end
    
    # Check for prices that are too good to be true
    if current_price < (filter.target_price * 0.3) # Less than 30% of target
      return true
    end
    
    # Check for missing critical data
    if best_match[:airline].blank? || best_match[:flight_number].blank?
      return true
    end
    
    false
  end

  # Check if this is a significant price change from recent history
  def is_significant_price_change?(filter, current_price)
    # Get recent price history for this route
    recent_prices = FlightPriceHistory.by_route(filter.route_description)
                                     .where('timestamp >= ?', 24.hours.ago)
                                     .valid_prices
                                     .order(:timestamp)
                                     .pluck(:price)
    
    return true if recent_prices.empty? # No recent data, assume significant
    
    # Calculate if this is a significant drop from recent average
    recent_average = recent_prices.sum.to_f / recent_prices.length
    drop_percentage = ((recent_average - current_price) / recent_average * 100).round(2)
    
    # Consider significant if it's at least 10% below recent average
    drop_percentage >= 10.0
  end

  # Calculate confidence score for the price break
  def calculate_confidence_score(filter, best_match, price_drop_percentage)
    score = 0.5 # Base score
    
    # Higher confidence for larger price drops
    score += [price_drop_percentage / 100.0, 0.3].min
    
    # Higher confidence for direct flights
    if best_match[:stops] == 0
      score += 0.1
    end
    
    # Higher confidence for well-known airlines
    if best_match[:airline].present?
      major_airlines = %w[AA DL UA WN B6 AS F9 NK G4]
      if major_airlines.include?(best_match[:airline])
        score += 0.1
      end
    end
    
    # Higher confidence for recent data
    if best_match[:raw_data] && best_match[:raw_data][:data_timestamp]
      data_age = Time.current - best_match[:raw_data][:data_timestamp]
      if data_age < 1.hour
        score += 0.1
      end
    end
    
    # Cap at 1.0
    [score, 1.0].min
  end

  # Trigger a price break alert with smart intelligence
  def trigger_price_break_alert(filter, price_analysis)
    @alerts_triggered += 1
    
    # Create or update flight alert
    alert = FlightAlert.find_or_initialize_by(flight_filter: filter)
    alert.assign_attributes(
      origin: filter.origin_airports_array.first,
      destination: filter.destination_airports_array.first,
      departure_date: filter.departure_dates_array.first,
      target_price: filter.target_price,
      current_price: price_analysis[:best_price],
      price_drop_percentage: price_analysis[:price_drop_percentage],
      alert_quality_score: price_analysis[:confidence_score],
      status: 'triggered'
    )
    
    # Add trigger record
    alert.alert_triggers ||= []
    alert.alert_triggers << {
      timestamp: Time.current,
      price: price_analysis[:best_price],
      provider: price_analysis[:best_match][:provider],
      drop_amount: filter.target_price - price_analysis[:best_price],
      drop_percentage: price_analysis[:price_drop_percentage],
      confidence_score: price_analysis[:confidence_score],
      analysis_details: price_analysis[:analysis_details]
    }
    
    alert.save!
    
    # Use smart alert intelligence to determine if alert should be sent
    intelligence = AlertIntelligenceService.new(alert, price_analysis[:best_price], {
      historical_data: get_historical_data_for_alert(alert),
      user_preferences: get_user_preferences(alert)
    })
    
    # Only proceed if intelligence system approves the alert
    if intelligence.should_send_alert?
      # Generate smart content
      smart_content = intelligence.generate_alert_content
      
      # Schedule smart alert delivery
      AlertDeliveryJob.perform_later(alert.id, :all, {
        smart_content: smart_content,
        urgency: smart_content[:urgency],
        optimal_delivery_time: intelligence.optimal_delivery_time
      })
      
      Rails.logger.info "Smart price break alert triggered for filter #{filter.id}: #{price_analysis[:best_price]} (was #{filter.target_price}) - Urgency: #{smart_content[:urgency]}"
    else
      # Log that alert was filtered out by intelligence system
      Rails.logger.info "Price break alert filtered out by intelligence system for filter #{filter.id}: #{price_analysis[:best_price]} (was #{filter.target_price})"
      
      # Update alert status to indicate it was filtered
      alert.update!(status: 'active') # Keep it active for future monitoring
    end
    
    # Update alert quality score
    quality_service = AlertQualityService.new(alert)
    quality_service.update_alert_quality
  end

  # Update filter's check time and schedule next check
  def update_filter_check_time(filter, price_analysis)
    # Update last checked time
    filter.update!(last_checked: Time.current)
    
    # Calculate next check interval based on urgency and results
    next_interval = calculate_next_check_interval(filter, price_analysis)
    
    # Schedule next check
    filter.update!(next_check_scheduled: Time.current + next_interval)
    
    Rails.logger.debug "Scheduled next check for filter #{filter.id} in #{next_interval / 1.hour} hours"
  end

  # Calculate next check interval based on various factors
  def calculate_next_check_interval(filter, price_analysis)
    base_interval = case filter.monitor_frequency
                   when 'real-time'
                     30.minutes
                   when 'hourly'
                     1.hour
                   when 'daily'
                     24.hours
                   when 'weekly'
                     7.days
                   else
                     6.hours
                   end
    
    # Adjust based on urgency
    if filter.is_urgent?
      base_interval = [base_interval, 1.hour].min
    end
    
    # Adjust based on recent activity
    if price_analysis[:price_break_detected]
      # Check more frequently after a price break
      base_interval = [base_interval, 2.hours].min
    end
    
    # Add some randomization to prevent thundering herd
    jitter = rand(0.1..0.3) * base_interval
    base_interval + jitter
  end

  # Store price history for trend analysis
  def store_price_history(filter, prices)
    return if prices.empty?
    
    prices.each do |price|
      FlightPriceHistory.create!(
        route: filter.route_description,
        date: filter.departure_dates_array.first,
        provider: price[:provider] || price['provider'] || 'unknown',
        price: price[:price] || price['price'],
        booking_class: price[:cabin_class] || price['cabin_class'] || 'economy',
        timestamp: Time.current,
        data_quality_score: 1.0,
        price_validation_status: 'valid'
      )
    rescue => e
      Rails.logger.error "Failed to store price history: #{e.message}"
    end
  end

  # Build search parameters for a filter
  def build_search_params(filter)
    {
      origin: filter.origin_airports_array.first,
      destination: filter.destination_airports_array.first,
      departure_date: filter.departure_dates_array.first,
      return_date: filter.return_dates_array.first,
      passengers: filter.passenger_count,
      cabin_class: filter.cabin_class,
      max_stops: filter.max_stops,
      currency: 'USD'
    }
  end

  # Schedule next check for a filter
  def schedule_next_check(filter, reason = :normal)
    interval = case reason
              when :no_data
                2.hours
              when :error
                4.hours
              when :urgent
                30.minutes
              else
                calculate_next_check_interval(filter, { price_break_detected: false })
              end
    
    filter.update!(
      last_checked: Time.current,
      next_check_scheduled: Time.current + interval
    )
  end

  # Get monitoring statistics
  def self.monitoring_stats
    {
      active_filters: FlightFilter.active.count,
      total_alerts: FlightAlert.count,
      triggered_alerts: FlightAlert.where(status: 'triggered').count,
      recent_price_checks: FlightPriceHistory.where('timestamp >= ?', 1.hour.ago).count,
      system_health: calculate_system_health
    }
  end

  # Calculate overall system health
  def self.calculate_system_health
    # Check if monitoring is running
    last_check = FlightFilter.maximum(:last_checked)
    return 'unhealthy' if last_check.nil? || last_check < 1.hour.ago
    
    # Check error rates
    recent_errors = FlightAlert.where('created_at >= ?', 1.day.ago)
                              .where('alert_quality_score < ?', 0.5)
                              .count
    
    total_alerts = FlightAlert.where('created_at >= ?', 1.day.ago).count
    error_rate = total_alerts > 0 ? recent_errors.to_f / total_alerts : 0
    
    case
    when error_rate > 0.5
      'unhealthy'
    when error_rate > 0.2
      'degraded'
    else
      'healthy'
    end
  end

  private

  # Get historical data for alert intelligence
  def get_historical_data_for_alert(alert)
    route = alert.route_description
    
    # Get recent price history for this route
    recent_prices = FlightPriceHistory.by_route(route)
                                    .where('timestamp >= ?', 30.days.ago)
                                    .valid_prices
                                    .order(:timestamp)
                                    .limit(50)
    
    recent_prices.map do |price_record|
      {
        timestamp: price_record.timestamp,
        price: price_record.price,
        provider: price_record.provider,
        quality_score: price_record.data_quality_score
      }
    end
  end

  # Get user preferences for alert intelligence
  def get_user_preferences(alert)
    user = alert.flight_filter&.user
    return {} unless user
    
    {
      notification_preferences: user.notification_preferences || {},
      alert_frequency: user.alert_frequency || 'normal',
      timezone: user.timezone || 'UTC',
      has_mobile_app: user.has_mobile_app? || false,
      phone_number: user.phone_number,
      preferred_booking_sites: user.preferred_booking_sites || []
    }
  end
end
