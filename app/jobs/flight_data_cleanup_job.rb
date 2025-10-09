class FlightDataCleanupJob < ApplicationJob
  queue_as :cleanup

  # Retry on specific errors
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  retry_on ActiveRecord::StatementTimeout, wait: 2.minutes, attempts: 2

  # Discard on specific errors
  discard_on ActiveRecord::RecordNotFound
  discard_on ArgumentError

  def perform(cleanup_type = :full)
    Rails.logger.info "Starting flight data cleanup job (#{cleanup_type})"
    
    start_time = Time.current
    
    case cleanup_type
    when :full
      result = perform_full_cleanup
    when :old_data
      result = cleanup_old_data
    when :invalid_data
      result = cleanup_invalid_data
    when :duplicates
      result = cleanup_duplicates
    when :suspicious_data
      result = cleanup_suspicious_data
    else
      result = perform_full_cleanup
    end
    
    duration = Time.current - start_time
    
    # Log results
    log_cleanup_results(result, duration, cleanup_type)
    
    # Schedule next cleanup run
    schedule_next_cleanup(cleanup_type)
    
    result
  rescue => e
    Rails.logger.error "Flight data cleanup job failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    { success: false, error: e.message }
  end

  private

  # Perform full cleanup
  def perform_full_cleanup
    results = {
      success: true,
      old_data_removed: 0,
      invalid_data_removed: 0,
      duplicates_removed: 0,
      suspicious_data_flagged: 0,
      errors: []
    }
    
    # Clean up old data
    begin
      old_data_result = cleanup_old_data
      results[:old_data_removed] = old_data_result[:removed_count] || 0
      results[:errors].concat(old_data_result[:errors] || [])
    rescue => e
      results[:errors] << "Old data cleanup failed: #{e.message}"
    end
    
    # Clean up invalid data
    begin
      invalid_data_result = cleanup_invalid_data
      results[:invalid_data_removed] = invalid_data_result[:removed_count] || 0
      results[:errors].concat(invalid_data_result[:errors] || [])
    rescue => e
      results[:errors] << "Invalid data cleanup failed: #{e.message}"
    end
    
    # Clean up duplicates
    begin
      duplicates_result = cleanup_duplicates
      results[:duplicates_removed] = duplicates_result[:removed_count] || 0
      results[:errors].concat(duplicates_result[:errors] || [])
    rescue => e
      results[:errors] << "Duplicates cleanup failed: #{e.message}"
    end
    
    # Flag suspicious data
    begin
      suspicious_result = cleanup_suspicious_data
      results[:suspicious_data_flagged] = suspicious_result[:flagged_count] || 0
      results[:errors].concat(suspicious_result[:errors] || [])
    rescue => e
      results[:errors] << "Suspicious data cleanup failed: #{e.message}"
    end
    
    # Update cleanup metrics
    update_cleanup_metrics(results)
    
    results
  end

  # Clean up old data
  def cleanup_old_data
    result = { success: true, removed_count: 0, errors: [] }
    
    # Clean up old price history (keep 90 days)
    old_price_history = FlightPriceHistory.where('date < ?', 90.days.ago)
    removed_price_history = old_price_history.delete_all
    result[:removed_count] += removed_price_history
    
    # Clean up old provider data (keep 7 days)
    old_provider_data = FlightProviderDatum.where('data_timestamp < ?', 7.days.ago)
    removed_provider_data = old_provider_data.delete_all
    result[:removed_count] += removed_provider_data
    
    # Clean up old alerts (keep 1 year)
    old_alerts = FlightAlert.where('created_at < ?', 1.year.ago)
                           .where(status: ['expired', 'triggered'])
    removed_alerts = old_alerts.delete_all
    result[:removed_count] += removed_alerts
    
    Rails.logger.info "Cleaned up #{result[:removed_count]} old records"
    result
  rescue => e
    result[:success] = false
    result[:errors] << "Old data cleanup error: #{e.message}"
    result
  end

  # Clean up invalid data
  def cleanup_invalid_data
    result = { success: true, removed_count: 0, errors: [] }
    
    # Remove price history with invalid prices
    invalid_price_history = FlightPriceHistory.where(price_validation_status: 'invalid')
    removed_price_history = invalid_price_history.delete_all
    result[:removed_count] += removed_price_history
    
    # Remove provider data with invalid status
    invalid_provider_data = FlightProviderDatum.where(validation_status: 'invalid')
    removed_provider_data = invalid_provider_data.delete_all
    result[:removed_count] += removed_provider_data
    
    # Remove alerts with invalid data
    invalid_alerts = FlightAlert.where('target_price <= 0 OR current_price <= 0')
    removed_alerts = invalid_alerts.delete_all
    result[:removed_count] += removed_alerts
    
    Rails.logger.info "Cleaned up #{result[:removed_count]} invalid records"
    result
  rescue => e
    result[:success] = false
    result[:errors] << "Invalid data cleanup error: #{e.message}"
    result
  end

  # Clean up duplicate data
  def cleanup_duplicates
    result = { success: true, removed_count: 0, errors: [] }
    
    # Clean up duplicate price history
    duplicate_price_history = find_duplicate_price_history
    duplicate_price_history.each do |group|
      # Keep the most recent record
      records = FlightPriceHistory.where(id: group)
      keep_record = records.order(:timestamp).last
      records.where.not(id: keep_record.id).delete_all
      result[:removed_count] += records.count - 1
    end
    
    # Clean up duplicate provider data
    duplicate_provider_data = find_duplicate_provider_data
    duplicate_provider_data.each do |group|
      # Keep the most recent valid record
      records = FlightProviderDatum.where(id: group)
      keep_record = records.valid_data.order(:data_timestamp).last || records.order(:data_timestamp).last
      records.where.not(id: keep_record.id).delete_all
      result[:removed_count] += records.count - 1
    end
    
    Rails.logger.info "Cleaned up #{result[:removed_count]} duplicate records"
    result
  rescue => e
    result[:success] = false
    result[:errors] << "Duplicates cleanup error: #{e.message}"
    result
  end

  # Find duplicate price history records
  def find_duplicate_price_history
    # Find records with same route, date, provider, and price
    FlightPriceHistory.group(:route, :date, :provider, :price)
                     .having('COUNT(*) > 1')
                     .pluck('ARRAY_AGG(id)')
  end

  # Find duplicate provider data records
  def find_duplicate_provider_data
    # Find records with same flight_identifier and provider
    FlightProviderDatum.group(:flight_identifier, :provider)
                      .having('COUNT(*) > 1')
                      .pluck('ARRAY_AGG(id)')
  end

  # Clean up suspicious data
  def cleanup_suspicious_data
    result = { success: true, flagged_count: 0, errors: [] }
    
    # Flag suspicious price history
    suspicious_price_history = detect_suspicious_price_history
    suspicious_price_history.each do |record_id|
      FlightPriceHistory.where(id: record_id).update_all(price_validation_status: 'suspicious')
      result[:flagged_count] += 1
    end
    
    # Flag suspicious provider data
    suspicious_provider_data = detect_suspicious_provider_data
    suspicious_provider_data.each do |record_id|
      FlightProviderDatum.where(id: record_id).update_all(validation_status: 'suspicious')
      result[:flagged_count] += 1
    end
    
    Rails.logger.info "Flagged #{result[:flagged_count]} suspicious records"
    result
  rescue => e
    result[:success] = false
    result[:errors] << "Suspicious data cleanup error: #{e.message}"
    result
  end

  # Detect suspicious price history records
  def detect_suspicious_price_history
    suspicious_ids = []
    
    # Find prices that are extremely low or high
    suspicious_prices = FlightPriceHistory.where('price < ? OR price > ?', 10, 50000)
    suspicious_ids.concat(suspicious_prices.pluck(:id))
    
    # Find prices that are outliers for their route
    routes = FlightPriceHistory.distinct.pluck(:route)
    routes.each do |route|
      route_prices = FlightPriceHistory.by_route(route).pluck(:price, :id)
      next if route_prices.length < 5
      
      prices = route_prices.map(&:first)
      mean = prices.sum.to_f / prices.length
      variance = prices.sum { |price| (price - mean) ** 2 } / prices.length
      standard_deviation = Math.sqrt(variance)
      
      # Flag prices more than 3 standard deviations from mean
      route_prices.each do |price, id|
        z_score = (price - mean).abs / standard_deviation
        if z_score > 3.0
          suspicious_ids << id
        end
      end
    end
    
    suspicious_ids.uniq
  end

  # Detect suspicious provider data records
  def detect_suspicious_provider_data
    suspicious_ids = []
    
    # Find records with missing critical data
    missing_data = FlightProviderDatum.where(
      'flight_identifier IS NULL OR flight_identifier = ? OR route IS NULL OR route = ?',
      '', ''
    )
    suspicious_ids.concat(missing_data.pluck(:id))
    
    # Find records with invalid pricing data
    invalid_pricing = FlightProviderDatum.where(
      "pricing->>'price' IS NULL OR pricing->>'price' = '' OR (pricing->>'price')::numeric <= 0"
    )
    suspicious_ids.concat(invalid_pricing.pluck(:id))
    
    # Find records with invalid schedule data
    invalid_schedule = FlightProviderDatum.where(
      "schedule->>'departure_time' IS NULL OR schedule->>'departure_time' = ''"
    )
    suspicious_ids.concat(invalid_schedule.pluck(:id))
    
    suspicious_ids.uniq
  end

  # Update cleanup metrics
  def update_cleanup_metrics(results)
    metrics = {
      last_cleanup: Time.current.iso8601,
      old_data_removed: results[:old_data_removed],
      invalid_data_removed: results[:invalid_data_removed],
      duplicates_removed: results[:duplicates_removed],
      suspicious_data_flagged: results[:suspicious_data_flagged],
      cleanup_success: results[:success],
      error_count: results[:errors].count
    }
    
    Rails.cache.write('cleanup_metrics', metrics, expires_in: 24.hours)
  end

  # Log cleanup results
  def log_cleanup_results(result, duration, cleanup_type)
    if result[:success]
      Rails.logger.info "Flight data cleanup completed successfully (#{cleanup_type})"
      Rails.logger.info "  Duration: #{duration.round(2)}s"
      Rails.logger.info "  Old data removed: #{result[:old_data_removed]}"
      Rails.logger.info "  Invalid data removed: #{result[:invalid_data_removed]}"
      Rails.logger.info "  Duplicates removed: #{result[:duplicates_removed]}"
      Rails.logger.info "  Suspicious data flagged: #{result[:suspicious_data_flagged]}"
      
      if result[:errors].any?
        Rails.logger.warn "  Errors encountered: #{result[:errors].count}"
        result[:errors].each { |error| Rails.logger.warn "    #{error}" }
      end
    else
      Rails.logger.error "Flight data cleanup failed (#{cleanup_type})"
      Rails.logger.error "  Duration: #{duration.round(2)}s"
      Rails.logger.error "  Error: #{result[:error]}"
    end
  end

  # Schedule next cleanup run
  def schedule_next_cleanup(cleanup_type)
    case cleanup_type
    when :full
      # Full cleanup every 24 hours
      next_run_time = 24.hours.from_now
    when :old_data
      # Old data cleanup every 12 hours
      next_run_time = 12.hours.from_now
    when :invalid_data
      # Invalid data cleanup every 6 hours
      next_run_time = 6.hours.from_now
    when :duplicates
      # Duplicates cleanup every 4 hours
      next_run_time = 4.hours.from_now
    when :suspicious_data
      # Suspicious data cleanup every 2 hours
      next_run_time = 2.hours.from_now
    else
      # Default to 12 hours
      next_run_time = 12.hours.from_now
    end
    
    # Add some randomization
    jitter = rand(0.1..0.3) * (next_run_time - Time.current)
    next_run_time += jitter
    
    FlightDataCleanupJob.set(wait_until: next_run_time).perform_later(cleanup_type)
    
    Rails.logger.info "Next cleanup scheduled for #{next_run_time}"
  end

  # Class method to start cleanup
  def self.start_cleanup
    # Cancel any existing cleanup jobs
    FlightDataCleanupJob.where(queue_name: 'cleanup').destroy_all
    
    # Start full cleanup
    FlightDataCleanupJob.perform_later(:full)
    
    # Start specific cleanups
    FlightDataCleanupJob.set(wait: 1.hour).perform_later(:old_data)
    FlightDataCleanupJob.set(wait: 2.hours).perform_later(:invalid_data)
    FlightDataCleanupJob.set(wait: 3.hours).perform_later(:duplicates)
    FlightDataCleanupJob.set(wait: 4.hours).perform_later(:suspicious_data)
    
    Rails.logger.info "Flight data cleanup started"
  end

  # Class method to get cleanup status
  def self.cleanup_status
    metrics = Rails.cache.read('cleanup_metrics') || {}
    
    {
      is_running: FlightDataCleanupJob.where(queue_name: 'cleanup').exists?,
      last_cleanup: metrics[:last_cleanup],
      old_data_removed: metrics[:old_data_removed] || 0,
      invalid_data_removed: metrics[:invalid_data_removed] || 0,
      duplicates_removed: metrics[:duplicates_removed] || 0,
      suspicious_data_flagged: metrics[:suspicious_data_flagged] || 0
    }
  end

  # Class method to get data quality metrics
  def self.data_quality_metrics
    {
      total_price_history: FlightPriceHistory.count,
      valid_price_history: FlightPriceHistory.valid_prices.count,
      suspicious_price_history: FlightPriceHistory.where(price_validation_status: 'suspicious').count,
      invalid_price_history: FlightPriceHistory.where(price_validation_status: 'invalid').count,
      
      total_provider_data: FlightProviderDatum.count,
      valid_provider_data: FlightProviderDatum.valid_data.count,
      suspicious_provider_data: FlightProviderDatum.where(validation_status: 'suspicious').count,
      invalid_provider_data: FlightProviderDatum.where(validation_status: 'invalid').count,
      
      total_alerts: FlightAlert.count,
      active_alerts: FlightAlert.active.count,
      triggered_alerts: FlightAlert.where(status: 'triggered').count,
      expired_alerts: FlightAlert.where(status: 'expired').count
    }
  end
end



