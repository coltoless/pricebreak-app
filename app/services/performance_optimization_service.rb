class PerformanceOptimizationService
  include ActiveModel::Validations

  # Cache configuration
  CACHE_NAMESPACES = {
    price_history: 'price_history',
    route_analysis: 'route_analysis',
    provider_stats: 'provider_stats',
    filter_analysis: 'filter_analysis',
    monitoring_metrics: 'monitoring_metrics'
  }.freeze

  CACHE_DURATIONS = {
    price_history: 1.hour,
    route_analysis: 6.hours,
    provider_stats: 24.hours,
    filter_analysis: 2.hours,
    monitoring_metrics: 30.minutes
  }.freeze

  # Performance thresholds
  PERFORMANCE_THRESHOLDS = {
    max_response_time: 5.seconds,
    max_memory_usage: 500.megabytes,
    max_database_queries: 100,
    max_api_calls_per_minute: 60
  }.freeze

  def initialize
    @performance_metrics = {}
    @cache_hits = 0
    @cache_misses = 0
  end

  # Main performance optimization method
  def optimize_performance(operation_type, &block)
    start_time = Time.current
    start_memory = memory_usage
    
    begin
      result = yield
      
      # Record performance metrics
      duration = Time.current - start_time
      memory_delta = memory_usage - start_memory
      
      record_performance_metrics(operation_type, duration, memory_delta, true)
      
      result
    rescue => e
      duration = Time.current - start_time
      memory_delta = memory_usage - start_memory
      
      record_performance_metrics(operation_type, duration, memory_delta, false)
      
      Rails.logger.error "Performance optimization error in #{operation_type}: #{e.message}"
      raise
    end
  end

  # Caching methods
  def cache_price_history(route, date_range, &block)
    cache_key = "price_history:#{route}:#{date_range.begin}:#{date_range.end}"
    cache_namespace = CACHE_NAMESPACES[:price_history]
    cache_duration = CACHE_DURATIONS[:price_history]
    
    Rails.cache.fetch(cache_key, namespace: cache_namespace, expires_in: cache_duration) do
      @cache_misses += 1
      yield
    end.tap { @cache_hits += 1 }
  end

  def cache_route_analysis(route, &block)
    cache_key = "route_analysis:#{route}"
    cache_namespace = CACHE_NAMESPACES[:route_analysis]
    cache_duration = CACHE_DURATIONS[:route_analysis]
    
    Rails.cache.fetch(cache_key, namespace: cache_namespace, expires_in: cache_duration) do
      @cache_misses += 1
      yield
    end.tap { @cache_hits += 1 }
  end

  def cache_provider_stats(provider, &block)
    cache_key = "provider_stats:#{provider}"
    cache_namespace = CACHE_NAMESPACES[:provider_stats]
    cache_duration = CACHE_DURATIONS[:provider_stats]
    
    Rails.cache.fetch(cache_key, namespace: cache_namespace, expires_in: cache_duration) do
      @cache_misses += 1
      yield
    end.tap { @cache_hits += 1 }
  end

  def cache_filter_analysis(filter_id, &block)
    cache_key = "filter_analysis:#{filter_id}"
    cache_namespace = CACHE_NAMESPACES[:filter_analysis]
    cache_duration = CACHE_DURATIONS[:filter_analysis]
    
    Rails.cache.fetch(cache_key, namespace: cache_namespace, expires_in: cache_duration) do
      @cache_misses += 1
      yield
    end.tap { @cache_hits += 1 }
  end

  # Batch processing methods
  def batch_process_filters(filters, batch_size = 10)
    results = []
    
    filters.in_groups_of(batch_size, false) do |filter_batch|
      batch_results = filter_batch.map do |filter|
        begin
          yield(filter)
        rescue => e
          Rails.logger.error "Error processing filter #{filter.id}: #{e.message}"
          { success: false, error: e.message, filter_id: filter.id }
        end
      end
      
      results.concat(batch_results)
      
      # Add small delay between batches to prevent overwhelming the system
      sleep(0.1) if filter_batch.length == batch_size
    end
    
    results
  end

  def batch_process_prices(prices, batch_size = 50)
    results = []
    
    prices.in_groups_of(batch_size, false) do |price_batch|
      batch_results = price_batch.map do |price|
        begin
          yield(price)
        rescue => e
          Rails.logger.error "Error processing price: #{e.message}"
          { success: false, error: e.message, price: price }
        end
      end
      
      results.concat(batch_results)
    end
    
    results
  end

  # Database optimization methods
  def optimize_database_queries
    # Enable query caching
    ActiveRecord::Base.connection.enable_query_cache!
    
    # Set connection pool size based on environment
    pool_size = case Rails.env
               when 'production'
                 20
               when 'staging'
                 10
               else
                 5
               end
    
    ActiveRecord::Base.connection_pool.size = pool_size
  end

  def prefetch_associations(records, associations)
    ActiveRecord::Associations::Preloader.new(
      records: records,
      associations: associations
    ).call
  end

  # Memory management methods
  def memory_usage
    `ps -o rss= -p #{Process.pid}`.to_i * 1024 # Convert KB to bytes
  end

  def check_memory_usage
    current_memory = memory_usage
    max_memory = PERFORMANCE_THRESHOLDS[:max_memory_usage]
    
    if current_memory > max_memory
      Rails.logger.warn "High memory usage detected: #{current_memory / 1.megabyte}MB"
      
      # Trigger garbage collection
      GC.start
      
      # Clear caches if still high
      if memory_usage > max_memory
        clear_old_caches
      end
    end
  end

  def clear_old_caches
    CACHE_NAMESPACES.each do |namespace, cache_namespace|
      Rails.cache.delete_matched("#{cache_namespace}:*")
    end
    
    Rails.logger.info "Cleared old caches due to high memory usage"
  end

  # API rate limiting methods
  def rate_limit_api_calls(provider, max_calls_per_minute = 60)
    cache_key = "api_rate_limit:#{provider}:#{Time.current.strftime('%Y%m%d%H%M')}"
    
    current_calls = Rails.cache.read(cache_key) || 0
    
    if current_calls >= max_calls_per_minute
      raise "Rate limit exceeded for #{provider}: #{current_calls}/#{max_calls_per_minute} calls per minute"
    end
    
    Rails.cache.write(cache_key, current_calls + 1, expires_in: 1.minute)
  end

  def check_api_rate_limits(providers)
    providers.each do |provider|
      rate_limit_api_calls(provider)
    end
  end

  # Async processing methods
  def async_process_with_priority(operation, priority = :normal)
    case priority
    when :high
      queue_name = 'monitoring'
    when :normal
      queue_name = 'default'
    when :low
      queue_name = 'cleanup'
    else
      queue_name = 'default'
    end
    
    operation.set(queue: queue_name).perform_later
  end

  def schedule_background_cleanup
    # Schedule cleanup jobs with different priorities
    FlightDataCleanupJob.set(queue: 'cleanup', priority: :low).perform_later(:old_data)
    FlightDataCleanupJob.set(queue: 'cleanup', priority: :low).perform_later(:invalid_data)
    FlightDataCleanupJob.set(queue: 'cleanup', priority: :low).perform_later(:duplicates)
  end

  # Performance monitoring methods
  def record_performance_metrics(operation_type, duration, memory_delta, success)
    @performance_metrics[operation_type] ||= {
      total_calls: 0,
      successful_calls: 0,
      failed_calls: 0,
      total_duration: 0.0,
      max_duration: 0.0,
      min_duration: Float::INFINITY,
      total_memory_delta: 0,
      max_memory_delta: 0
    }
    
    metrics = @performance_metrics[operation_type]
    metrics[:total_calls] += 1
    metrics[:total_duration] += duration
    metrics[:total_memory_delta] += memory_delta
    
    if success
      metrics[:successful_calls] += 1
    else
      metrics[:failed_calls] += 1
    end
    
    metrics[:max_duration] = [metrics[:max_duration], duration].max
    metrics[:min_duration] = [metrics[:min_duration], duration].min
    metrics[:max_memory_delta] = [metrics[:max_memory_delta], memory_delta].max
    
    # Store in cache for monitoring dashboard
    Rails.cache.write(
      "performance_metrics:#{operation_type}",
      metrics,
      expires_in: 1.hour
    )
  end

  def get_performance_metrics(operation_type = nil)
    if operation_type
      @performance_metrics[operation_type] || {}
    else
      @performance_metrics
    end
  end

  def get_cache_stats
    {
      cache_hits: @cache_hits,
      cache_misses: @cache_misses,
      hit_rate: @cache_hits + @cache_misses > 0 ? (@cache_hits.to_f / (@cache_hits + @cache_misses) * 100).round(2) : 0
    }
  end

  # System health methods
  def check_system_health
    health_status = {
      memory_usage: memory_usage,
      memory_usage_mb: (memory_usage / 1.megabyte).round(2),
      memory_threshold_exceeded: memory_usage > PERFORMANCE_THRESHOLDS[:max_memory_usage],
      cache_stats: get_cache_stats,
      performance_metrics: get_performance_metrics,
      database_connections: ActiveRecord::Base.connection_pool.size,
      active_connections: ActiveRecord::Base.connection_pool.connections.size,
      sidekiq_stats: get_sidekiq_stats
    }
    
    health_status[:overall_health] = calculate_overall_health(health_status)
    health_status
  end

  def calculate_overall_health(health_status)
    score = 1.0
    
    # Reduce score for high memory usage
    if health_status[:memory_threshold_exceeded]
      score -= 0.3
    end
    
    # Reduce score for low cache hit rate
    if health_status[:cache_stats][:hit_rate] < 50
      score -= 0.2
    end
    
    # Reduce score for high database connection usage
    connection_ratio = health_status[:active_connections].to_f / health_status[:database_connections]
    if connection_ratio > 0.8
      score -= 0.2
    end
    
    # Reduce score for Sidekiq issues
    if health_status[:sidekiq_stats][:failed] > 10
      score -= 0.3
    end
    
    case score
    when 0.8..1.0
      'healthy'
    when 0.6..0.8
      'degraded'
    else
      'unhealthy'
    end
  end

  def get_sidekiq_stats
    begin
      stats = Sidekiq::Stats.new
      {
        processed: stats.processed,
        failed: stats.failed,
        enqueued: stats.enqueued,
        queues: stats.queues
      }
    rescue => e
      Rails.logger.error "Error getting Sidekiq stats: #{e.message}"
      { processed: 0, failed: 0, enqueued: 0, queues: {} }
    end
  end

  # Optimization recommendations
  def get_optimization_recommendations
    recommendations = []
    health_status = check_system_health
    
    # Memory recommendations
    if health_status[:memory_threshold_exceeded]
      recommendations << {
        type: 'memory',
        priority: 'high',
        message: 'High memory usage detected. Consider increasing server memory or optimizing data processing.',
        action: 'clear_old_caches'
      }
    end
    
    # Cache recommendations
    if health_status[:cache_stats][:hit_rate] < 50
      recommendations << {
        type: 'cache',
        priority: 'medium',
        message: 'Low cache hit rate. Consider increasing cache duration or improving cache keys.',
        action: 'optimize_cache_strategy'
      }
    end
    
    # Database recommendations
    connection_ratio = health_status[:active_connections].to_f / health_status[:database_connections]
    if connection_ratio > 0.8
      recommendations << {
        type: 'database',
        priority: 'high',
        message: 'High database connection usage. Consider increasing connection pool size.',
        action: 'increase_connection_pool'
      }
    end
    
    # Sidekiq recommendations
    if health_status[:sidekiq_stats][:failed] > 10
      recommendations << {
        type: 'sidekiq',
        priority: 'medium',
        message: 'High Sidekiq failure rate. Check job error logs and retry logic.',
        action: 'investigate_sidekiq_failures'
      }
    end
    
    recommendations
  end

  # Advanced caching strategies
  def cache_with_invalidation(cache_key, expires_in, &block)
    cached_data = Rails.cache.read(cache_key)
    
    if cached_data && !cache_expired?(cached_data, expires_in)
      @cache_hits += 1
      return cached_data[:data]
    end
    
    @cache_misses += 1
    fresh_data = yield
    
    Rails.cache.write(cache_key, {
      data: fresh_data,
      cached_at: Time.current,
      expires_in: expires_in
    }, expires_in: expires_in)
    
    fresh_data
  end

  def cache_expired?(cached_data, expires_in)
    return true unless cached_data.is_a?(Hash) && cached_data[:cached_at]
    
    Time.current - cached_data[:cached_at] > expires_in
  end

  # Database query optimization
  def optimize_query_with_explain(query)
    explanation = ActiveRecord::Base.connection.execute("EXPLAIN #{query}")
    
    # Analyze query performance and provide recommendations
    analyze_query_performance(explanation)
  end

  def analyze_query_performance(explanation)
    recommendations = []
    
    explanation.each do |row|
      if row['Extra']&.include?('Using filesort')
        recommendations << 'Consider adding an index to avoid filesort'
      end
      
      if row['Extra']&.include?('Using temporary')
        recommendations << 'Consider optimizing GROUP BY or ORDER BY clauses'
      end
      
      if row['rows']&.to_i > 1000
        recommendations << 'Large result set detected - consider adding WHERE conditions'
      end
    end
    
    recommendations
  end

  # Advanced memory management
  def optimize_memory_usage
    # Force garbage collection
    GC.start
    
    # Clear unused caches
    clear_unused_caches
    
    # Optimize ActiveRecord connections
    ActiveRecord::Base.clear_active_connections!
    
    # Log memory optimization
    Rails.logger.info "Memory optimization completed. Current usage: #{memory_usage / 1.megabyte}MB"
  end

  def clear_unused_caches
    # Clear caches older than 1 hour
    CACHE_NAMESPACES.each do |namespace, cache_namespace|
      Rails.cache.delete_matched("#{cache_namespace}:*", expires_in: 1.hour.ago)
    end
  end

  # Advanced batch processing with progress tracking
  def batch_process_with_progress(items, batch_size = 10, &block)
    total_items = items.count
    processed_items = 0
    results = []
    
    items.in_batches(of: batch_size) do |batch|
      batch_results = batch.map do |item|
        begin
          result = yield(item)
          processed_items += 1
          
          # Log progress every 10%
          if processed_items % (total_items / 10) == 0
            progress = (processed_items.to_f / total_items * 100).round(1)
            Rails.logger.info "Batch processing progress: #{progress}% (#{processed_items}/#{total_items})"
          end
          
          result
        rescue => e
          Rails.logger.error "Error processing item: #{e.message}"
          { success: false, error: e.message }
        end
      end
      
      results.concat(batch_results)
      
      # Small delay to prevent overwhelming the system
      sleep(0.05)
    end
    
    Rails.logger.info "Batch processing completed: #{processed_items}/#{total_items} items processed"
    results
  end

  # Advanced error handling and recovery
  def with_circuit_breaker(operation_name, failure_threshold = 5, timeout = 30.seconds)
    circuit_key = "circuit_breaker:#{operation_name}"
    failures = Rails.cache.read(circuit_key) || 0
    
    if failures >= failure_threshold
      Rails.logger.warn "Circuit breaker open for #{operation_name}. Skipping operation."
      return { success: false, error: 'Circuit breaker open', skipped: true }
    end
    
    begin
      Timeout::timeout(timeout) do
        result = yield
        # Reset failure count on success
        Rails.cache.delete(circuit_key)
        result
      end
    rescue => e
      # Increment failure count
      Rails.cache.write(circuit_key, failures + 1, expires_in: 5.minutes)
      Rails.logger.error "Circuit breaker failure for #{operation_name}: #{e.message}"
      { success: false, error: e.message }
    end
  end

  # Performance profiling
  def profile_operation(operation_name, &block)
    start_time = Time.current
    start_memory = memory_usage
    start_queries = ActiveRecord::Base.connection.query_cache.size
    
    result = yield
    
    end_time = Time.current
    end_memory = memory_usage
    end_queries = ActiveRecord::Base.connection.query_cache.size
    
    profile_data = {
      operation: operation_name,
      duration: end_time - start_time,
      memory_delta: end_memory - start_memory,
      queries_executed: end_queries - start_queries,
      timestamp: Time.current.iso8601
    }
    
    # Store profile data
    Rails.cache.write("profile:#{operation_name}:#{Time.current.to_i}", profile_data, expires_in: 24.hours)
    
    Rails.logger.info "Profile #{operation_name}: #{profile_data[:duration]}s, #{profile_data[:memory_delta]}MB, #{profile_data[:queries_executed]} queries"
    
    result
  end

  # Advanced monitoring and alerting
  def monitor_performance_thresholds
    health = check_system_health
    alerts = []
    
    # Memory threshold alert
    if health[:memory_usage_mb] > 400
      alerts << {
        type: 'memory',
        severity: 'warning',
        message: "High memory usage: #{health[:memory_usage_mb]}MB",
        threshold: 400,
        current: health[:memory_usage_mb]
      }
    end
    
    # Cache hit rate alert
    if health[:cache_stats][:hit_rate] < 60
      alerts << {
        type: 'cache',
        severity: 'warning',
        message: "Low cache hit rate: #{health[:cache_stats][:hit_rate]}%",
        threshold: 60,
        current: health[:cache_stats][:hit_rate]
      }
    end
    
    # Database connection alert
    connection_ratio = health[:active_connections].to_f / health[:database_connections]
    if connection_ratio > 0.9
      alerts << {
        type: 'database',
        severity: 'critical',
        message: "High database connection usage: #{(connection_ratio * 100).round(1)}%",
        threshold: 90,
        current: (connection_ratio * 100).round(1)
      }
    end
    
    alerts
  end

  # Class methods for system-wide optimization
  def self.optimize_system
    service = new
    
    # Optimize database
    service.optimize_database_queries
    
    # Schedule background cleanup
    service.schedule_background_cleanup
    
    # Optimize memory usage
    service.optimize_memory_usage
    
    # Check system health
    health = service.check_system_health
    
    # Check for performance alerts
    alerts = service.monitor_performance_thresholds
    
    Rails.logger.info "System optimization completed. Health: #{health[:overall_health]}"
    Rails.logger.warn "Performance alerts: #{alerts.count}" if alerts.any?
    
    {
      health: health,
      alerts: alerts,
      optimization_completed: true
    }
  end

  def self.get_system_performance_report
    service = new
    
    {
      health_status: service.check_system_health,
      cache_stats: service.get_cache_stats,
      performance_metrics: service.get_performance_metrics,
      recommendations: service.get_optimization_recommendations,
      alerts: service.monitor_performance_thresholds,
      timestamp: Time.current.iso8601
    }
  end

  def self.get_performance_trends(days = 7)
    trends = {}
    
    (0...days).each do |day_offset|
      date = day_offset.days.ago.to_date
      
      # Get cached profile data for the day
      day_profiles = Rails.cache.read_multi(
        *Rails.cache.read_matched("profile:*:#{date.to_time.to_i}")
      )
      
      trends[date.to_s] = {
        operations: day_profiles.count,
        total_duration: day_profiles.values.sum { |p| p[:duration] },
        total_memory: day_profiles.values.sum { |p| p[:memory_delta] },
        total_queries: day_profiles.values.sum { |p| p[:queries_executed] }
      }
    end
    
    trends
  end
end



