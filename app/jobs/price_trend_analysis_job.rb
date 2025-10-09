class PriceTrendAnalysisJob < ApplicationJob
  queue_as :analysis

  # Retry on specific errors
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  retry_on ActiveRecord::StatementTimeout, wait: 1.minute, attempts: 2

  # Discard on specific errors
  discard_on ActiveRecord::RecordNotFound
  discard_on ArgumentError

  def perform(analysis_type = :full)
    Rails.logger.info "Starting price trend analysis job (#{analysis_type})"
    
    start_time = Time.current
    
    case analysis_type
    when :full
      result = perform_full_analysis
    when :route_specific
      result = perform_route_analysis
    when :anomaly_detection
      result = detect_price_anomalies
    when :cleanup
      result = cleanup_old_data
    else
      result = perform_full_analysis
    end
    
    duration = Time.current - start_time
    
    # Log results
    log_analysis_results(result, duration, analysis_type)
    
    # Schedule next analysis run
    schedule_next_analysis(analysis_type)
    
    result
  rescue => e
    Rails.logger.error "Price trend analysis job failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    { success: false, error: e.message }
  end

  private

  # Perform full trend analysis
  def perform_full_analysis
    results = {
      success: true,
      routes_analyzed: 0,
      anomalies_detected: 0,
      trends_identified: 0,
      data_quality_improvements: 0,
      errors: []
    }
    
    # Get all unique routes with recent price data
    routes = FlightPriceHistory.where('timestamp >= ?', 7.days.ago)
                              .distinct
                              .pluck(:route)
    
    Rails.logger.info "Analyzing trends for #{routes.count} routes"
    
    routes.each do |route|
      begin
        route_analysis = analyze_route_trends(route)
        
        results[:routes_analyzed] += 1
        results[:anomalies_detected] += route_analysis[:anomalies_detected]
        results[:trends_identified] += route_analysis[:trends_identified]
        results[:data_quality_improvements] += route_analysis[:quality_improvements]
        
      rescue => e
        error_msg = "Error analyzing route #{route}: #{e.message}"
        results[:errors] << error_msg
        Rails.logger.error error_msg
      end
    end
    
    # Update system-wide trend metrics
    update_trend_metrics(results)
    
    results
  end

  # Analyze trends for a specific route
  def analyze_route_trends(route)
    analysis = {
      anomalies_detected: 0,
      trends_identified: 0,
      quality_improvements: 0,
      volatility_score: 0,
      price_forecast: nil
    }
    
    # Get price data for the last 30 days
    price_data = FlightPriceHistory.by_route(route)
                                  .where('timestamp >= ?', 30.days.ago)
                                  .valid_prices
                                  .order(:timestamp)
    
    return analysis if price_data.empty?
    
    prices = price_data.pluck(:price, :timestamp)
    
    # Detect price anomalies
    anomalies = detect_route_anomalies(route, prices)
    analysis[:anomalies_detected] = anomalies.count
    
    # Mark suspicious prices
    mark_suspicious_prices(anomalies)
    
    # Calculate volatility
    analysis[:volatility_score] = calculate_volatility_score(prices)
    
    # Identify trends
    trends = identify_price_trends(prices)
    analysis[:trends_identified] = trends.count
    
    # Generate price forecast
    analysis[:price_forecast] = generate_price_forecast(prices)
    
    # Improve data quality
    quality_improvements = improve_data_quality(route, price_data)
    analysis[:quality_improvements] = quality_improvements
    
    # Store analysis results
    store_route_analysis(route, analysis)
    
    analysis
  end

  # Detect price anomalies for a route
  def detect_route_anomalies(route, prices)
    return [] if prices.length < 5
    
    price_values = prices.map(&:first)
    timestamps = prices.map(&:last)
    
    # Calculate statistics
    mean = price_values.sum.to_f / price_values.length
    variance = price_values.sum { |price| (price - mean) ** 2 } / price_values.length
    standard_deviation = Math.sqrt(variance)
    
    # Find anomalies (prices more than 2 standard deviations from mean)
    anomalies = []
    price_values.each_with_index do |price, index|
      z_score = (price - mean).abs / standard_deviation
      
      if z_score > 2.0
        anomalies << {
          route: route,
          price: price,
          timestamp: timestamps[index],
          z_score: z_score,
          deviation_percentage: ((price - mean) / mean * 100).round(2)
        }
      end
    end
    
    anomalies
  end

  # Mark suspicious prices in the database
  def mark_suspicious_prices(anomalies)
    anomalies.each do |anomaly|
      FlightPriceHistory.where(
        route: anomaly[:route],
        price: anomaly[:price],
        timestamp: anomaly[:timestamp]
      ).update_all(price_validation_status: 'suspicious')
    end
  end

  # Calculate volatility score for a route
  def calculate_volatility_score(prices)
    return 0 if prices.length < 2
    
    price_values = prices.map(&:first)
    
    # Calculate coefficient of variation (standard deviation / mean)
    mean = price_values.sum.to_f / price_values.length
    variance = price_values.sum { |price| (price - mean) ** 2 } / price_values.length
    standard_deviation = Math.sqrt(variance)
    
    volatility = (standard_deviation / mean * 100).round(2)
    
    # Normalize to 0-1 scale
    [volatility / 100.0, 1.0].min
  end

  # Identify price trends
  def identify_price_trends(prices)
    return [] if prices.length < 3
    
    price_values = prices.map(&:first)
    timestamps = prices.map(&:last)
    
    trends = []
    
    # Simple trend detection using linear regression
    n = price_values.length
    sum_x = (0...n).sum
    sum_y = price_values.sum
    sum_xy = (0...n).sum { |i| i * price_values[i] }
    sum_x2 = (0...n).sum { |i| i * i }
    
    slope = (n * sum_xy - sum_x * sum_y).to_f / (n * sum_x2 - sum_x * sum_x)
    
    # Determine trend type
    if slope > 0.1
      trends << {
        type: 'increasing',
        strength: [slope / 10.0, 1.0].min,
        start_date: timestamps.first,
        end_date: timestamps.last
      }
    elsif slope < -0.1
      trends << {
        type: 'decreasing',
        strength: [slope.abs / 10.0, 1.0].min,
        start_date: timestamps.first,
        end_date: timestamps.last
      }
    else
      trends << {
        type: 'stable',
        strength: 0.1,
        start_date: timestamps.first,
        end_date: timestamps.last
      }
    end
    
    trends
  end

  # Generate price forecast
  def generate_price_forecast(prices)
    return nil if prices.length < 7
    
    price_values = prices.map(&:first)
    
    # Simple moving average forecast
    recent_prices = price_values.last(7)
    forecast_price = recent_prices.sum.to_f / recent_prices.length
    
    # Add some trend adjustment
    if price_values.length >= 14
      older_avg = price_values[-14..-8].sum.to_f / 7
      recent_avg = recent_prices.sum.to_f / 7
      trend = recent_avg - older_avg
      
      # Project trend forward
      forecast_price += trend * 0.5
    end
    
    {
      predicted_price: forecast_price.round(2),
      confidence: calculate_forecast_confidence(price_values),
      forecast_date: 7.days.from_now,
      based_on_days: prices.length
    }
  end

  # Calculate forecast confidence
  def calculate_forecast_confidence(price_values)
    return 0.1 if price_values.length < 7
    
    # Calculate R-squared for recent data
    recent_prices = price_values.last(7)
    mean = recent_prices.sum.to_f / recent_prices.length
    
    total_variance = recent_prices.sum { |price| (price - mean) ** 2 }
    return 0.1 if total_variance == 0
    
    # Simple confidence based on data consistency
    variance = total_variance / recent_prices.length
    standard_deviation = Math.sqrt(variance)
    coefficient_of_variation = standard_deviation / mean
    
    # Lower coefficient of variation = higher confidence
    confidence = [1.0 - coefficient_of_variation, 0.1].max
    [confidence, 0.9].min
  end

  # Improve data quality for a route
  def improve_data_quality(route, price_data)
    improvements = 0
    
    # Update quality scores based on recent analysis
    price_data.find_each do |record|
      old_score = record.data_quality_score
      record.update_quality_score
      
      if record.data_quality_score != old_score
        improvements += 1
      end
    end
    
    # Remove duplicate entries
    duplicates = price_data.group(:price, :timestamp)
                          .having('COUNT(*) > 1')
                          .count
    
    duplicates.each do |(price, timestamp), count|
      records = price_data.where(price: price, timestamp: timestamp)
      records.offset(1).destroy_all
      improvements += count - 1
    end
    
    improvements
  end

  # Store route analysis results
  def store_route_analysis(route, analysis)
    # Store in Redis for quick access
    cache_key = "route_analysis:#{route.gsub(/[^a-zA-Z0-9]/, '_')}"
    
    analysis_data = {
      route: route,
      analyzed_at: Time.current.iso8601,
      volatility_score: analysis[:volatility_score],
      price_forecast: analysis[:price_forecast],
      trends: analysis[:trends_identified],
      anomalies: analysis[:anomalies_detected],
      quality_improvements: analysis[:quality_improvements]
    }
    
    Rails.cache.write(cache_key, analysis_data, expires_in: 24.hours)
  end

  # Update system-wide trend metrics
  def update_trend_metrics(results)
    metrics = {
      last_analysis: Time.current.iso8601,
      routes_analyzed: results[:routes_analyzed],
      anomalies_detected: results[:anomalies_detected],
      trends_identified: results[:trends_identified],
      quality_improvements: results[:data_quality_improvements],
      analysis_success: results[:success]
    }
    
    Rails.cache.write('trend_analysis_metrics', metrics, expires_in: 24.hours)
  end

  # Log analysis results
  def log_analysis_results(result, duration, analysis_type)
    if result[:success]
      Rails.logger.info "Price trend analysis completed successfully (#{analysis_type})"
      Rails.logger.info "  Duration: #{duration.round(2)}s"
      Rails.logger.info "  Routes analyzed: #{result[:routes_analyzed]}"
      Rails.logger.info "  Anomalies detected: #{result[:anomalies_detected]}"
      Rails.logger.info "  Trends identified: #{result[:trends_identified]}"
      Rails.logger.info "  Quality improvements: #{result[:data_quality_improvements]}"
      
      if result[:errors].any?
        Rails.logger.warn "  Errors encountered: #{result[:errors].count}"
        result[:errors].each { |error| Rails.logger.warn "    #{error}" }
      end
    else
      Rails.logger.error "Price trend analysis failed (#{analysis_type})"
      Rails.logger.error "  Duration: #{duration.round(2)}s"
      Rails.logger.error "  Error: #{result[:error]}"
    end
  end

  # Schedule next analysis run
  def schedule_next_analysis(analysis_type)
    case analysis_type
    when :full
      # Full analysis every 6 hours
      next_run_time = 6.hours.from_now
    when :anomaly_detection
      # Anomaly detection every 2 hours
      next_run_time = 2.hours.from_now
    when :cleanup
      # Cleanup every 24 hours
      next_run_time = 24.hours.from_now
    else
      # Default to 4 hours
      next_run_time = 4.hours.from_now
    end
    
    # Add some randomization
    jitter = rand(0.1..0.3) * (next_run_time - Time.current)
    next_run_time += jitter
    
    PriceTrendAnalysisJob.set(wait_until: next_run_time).perform_later(analysis_type)
    
    Rails.logger.info "Next trend analysis scheduled for #{next_run_time}"
  end

  # Class method to start analysis
  def self.start_analysis
    # Cancel any existing analysis jobs
    PriceTrendAnalysisJob.where(queue_name: 'analysis').destroy_all
    
    # Start full analysis
    PriceTrendAnalysisJob.perform_later(:full)
    
    # Start anomaly detection (runs more frequently)
    PriceTrendAnalysisJob.set(wait: 1.hour).perform_later(:anomaly_detection)
    
    # Start cleanup (runs daily)
    PriceTrendAnalysisJob.set(wait: 1.day).perform_later(:cleanup)
    
    Rails.logger.info "Price trend analysis started"
  end

  # Class method to get analysis status
  def self.analysis_status
    metrics = Rails.cache.read('trend_analysis_metrics') || {}
    
    {
      is_running: PriceTrendAnalysisJob.where(queue_name: 'analysis').exists?,
      last_analysis: metrics[:last_analysis],
      routes_analyzed: metrics[:routes_analyzed] || 0,
      anomalies_detected: metrics[:anomalies_detected] || 0,
      trends_identified: metrics[:trends_identified] || 0
    }
  end
end



