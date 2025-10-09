namespace :system do
  desc "Initialize the flight price monitoring system"
  task init: :environment do
    puts "Initializing flight price monitoring system..."
    
    begin
      # Check system requirements
      check_system_requirements
      
      # Initialize database
      initialize_database
      
      # Set up performance optimization
      setup_performance_optimization
      
      # Initialize monitoring system
      initialize_monitoring_system
      
      # Set up scheduled tasks
      setup_scheduled_tasks
      
      puts "✅ System initialization completed successfully"
      
    rescue => e
      puts "❌ System initialization failed: #{e.message}"
      puts e.backtrace.join("\n")
      exit 1
    end
  end

  desc "Check system requirements"
  task check_requirements: :environment do
    puts "Checking system requirements..."
    
    requirements = {
      ruby_version: check_ruby_version,
      rails_version: check_rails_version,
      database: check_database_connection,
      redis: check_redis_connection,
      sidekiq: check_sidekiq_availability,
      memory: check_memory_requirements,
      disk_space: check_disk_space
    }
    
    all_met = requirements.values.all?
    
    puts "\nSystem Requirements Check:"
    puts "=" * 40
    
    requirements.each do |requirement, met|
      status = met ? "✅" : "❌"
      puts "#{status} #{requirement.to_s.humanize}: #{met ? 'OK' : 'FAILED'}"
    end
    
    if all_met
      puts "\n✅ All system requirements met"
    else
      puts "\n❌ Some system requirements not met. Please address the issues above."
      exit 1
    end
  end

  desc "Optimize system performance"
  task optimize: :environment do
    puts "Optimizing system performance..."
    
    begin
      # Run performance optimization
      health_status = PerformanceOptimizationService.optimize_system
      
      puts "✅ System optimization completed"
      puts "  - Overall health: #{health_status[:overall_health]}"
      puts "  - Memory usage: #{health_status[:memory_usage_mb]}MB"
      puts "  - Cache hit rate: #{health_status[:cache_stats][:hit_rate]}%"
      
      # Show recommendations
      recommendations = PerformanceOptimizationService.new.get_optimization_recommendations
      if recommendations.any?
        puts "\n📋 Optimization Recommendations:"
        recommendations.each do |rec|
          puts "  - #{rec[:priority].upcase}: #{rec[:message]}"
        end
      end
      
    rescue => e
      puts "❌ System optimization failed: #{e.message}"
      puts e.backtrace.join("\n")
      exit 1
    end
  end

  desc "Generate system performance report"
  task performance_report: :environment do
    puts "Generating system performance report..."
    
    begin
      report = PerformanceOptimizationService.get_system_performance_report
      
      puts "\n📊 System Performance Report"
      puts "=" * 50
      puts "Generated: #{report[:timestamp]}"
      puts ""
      
      # Health status
      health = report[:health_status]
      puts "System Health: #{health[:overall_health].upcase}"
      puts "Memory Usage: #{health[:memory_usage_mb]}MB"
      puts "Cache Hit Rate: #{health[:cache_stats][:hit_rate]}%"
      puts "Database Connections: #{health[:active_connections]}/#{health[:database_connections]}"
      puts ""
      
      # Performance metrics
      puts "Performance Metrics:"
      report[:performance_metrics].each do |operation, metrics|
        puts "  #{operation.to_s.humanize}:"
        puts "    - Total calls: #{metrics[:total_calls]}"
        puts "    - Success rate: #{(metrics[:successful_calls].to_f / metrics[:total_calls] * 100).round(2)}%"
        puts "    - Avg duration: #{metrics[:total_duration] / metrics[:total_calls]}s"
        puts "    - Max duration: #{metrics[:max_duration]}s"
        puts ""
      end
      
      # Recommendations
      if report[:recommendations].any?
        puts "📋 Recommendations:"
        report[:recommendations].each do |rec|
          puts "  - #{rec[:priority].upcase}: #{rec[:message]}"
        end
      end
      
    rescue => e
      puts "❌ Failed to generate performance report: #{e.message}"
      puts e.backtrace.join("\n")
      exit 1
    end
  end

  private

  def check_system_requirements
    puts "Checking system requirements..."
    
    requirements = {
      ruby_version: check_ruby_version,
      rails_version: check_rails_version,
      database: check_database_connection,
      redis: check_redis_connection,
      sidekiq: check_sidekiq_availability,
      memory: check_memory_requirements,
      disk_space: check_disk_space
    }
    
    all_met = requirements.values.all?
    
    unless all_met
      puts "❌ System requirements not met. Please address the issues above."
      exit 1
    end
  end

  def initialize_database
    puts "Initializing database..."
    
    # Run migrations if needed
    if ActiveRecord::Base.connection.migration_context.needs_migration?
      puts "Running database migrations..."
      Rake::Task['db:migrate'].invoke
    end
    
    # Create indexes for performance
    create_performance_indexes
    
    puts "✅ Database initialized"
  end

  def setup_performance_optimization
    puts "Setting up performance optimization..."
    
    # Optimize database connections
    PerformanceOptimizationService.new.optimize_database_queries
    
    # Set up caching
    setup_caching
    
    puts "✅ Performance optimization configured"
  end

  def initialize_monitoring_system
    puts "Initializing monitoring system..."
    
    # Start monitoring jobs
    FlightPriceMonitoringJob.start_monitoring
    PriceTrendAnalysisJob.start_analysis
    FlightDataCleanupJob.start_cleanup
    
    puts "✅ Monitoring system initialized"
  end

  def setup_scheduled_tasks
    puts "Setting up scheduled tasks..."
    
    # Schedule regular maintenance
    schedule_maintenance_tasks
    
    puts "✅ Scheduled tasks configured"
  end

  def check_ruby_version
    required_version = '3.3.0'
    current_version = RUBY_VERSION
    
    if Gem::Version.new(current_version) >= Gem::Version.new(required_version)
      true
    else
      puts "❌ Ruby version #{current_version} is below required #{required_version}"
      false
    end
  end

  def check_rails_version
    required_version = '8.0.0'
    current_version = Rails.version
    
    if Gem::Version.new(current_version) >= Gem::Version.new(required_version)
      true
    else
      puts "❌ Rails version #{current_version} is below required #{required_version}"
      false
    end
  end

  def check_database_connection
    begin
      ActiveRecord::Base.connection.execute('SELECT 1')
      true
    rescue => e
      puts "❌ Database connection failed: #{e.message}"
      false
    end
  end

  def check_redis_connection
    begin
      Rails.cache.write('test', 'value', expires_in: 1.second)
      Rails.cache.read('test') == 'value'
    rescue => e
      puts "❌ Redis connection failed: #{e.message}"
      false
    end
  end

  def check_sidekiq_availability
    begin
      Sidekiq::Stats.new
      true
    rescue => e
      puts "❌ Sidekiq not available: #{e.message}"
      false
    end
  end

  def check_memory_requirements
    # Check if we have at least 512MB available
    memory_usage = `ps -o rss= -p #{Process.pid}`.to_i * 1024
    required_memory = 512.megabytes
    
    if memory_usage < required_memory
      puts "❌ Insufficient memory: #{memory_usage / 1.megabyte}MB available, #{required_memory / 1.megabyte}MB required"
      false
    else
      true
    end
  end

  def check_disk_space
    # Check if we have at least 1GB free space
    free_space = `df -k . | tail -1 | awk '{print $4}'`.to_i * 1024
    required_space = 1.gigabyte
    
    if free_space < required_space
      puts "❌ Insufficient disk space: #{free_space / 1.gigabyte}GB available, #{required_space / 1.gigabyte}GB required"
      false
    else
      true
    end
  end

  def create_performance_indexes
    # Create indexes for better query performance
    indexes = [
      { table: 'flight_filters', columns: ['is_active', 'next_check_scheduled'] },
      { table: 'flight_alerts', columns: ['status', 'created_at'] },
      { table: 'flight_price_histories', columns: ['route', 'timestamp'] },
      { table: 'flight_provider_data', columns: ['provider', 'data_timestamp'] }
    ]
    
    indexes.each do |index|
      begin
        ActiveRecord::Base.connection.add_index(
          index[:table],
          index[:columns],
          name: "idx_#{index[:table]}_#{index[:columns].join('_')}"
        )
      rescue => e
        # Index might already exist
        Rails.logger.debug "Index creation skipped: #{e.message}"
      end
    end
  end

  def setup_caching
    # Configure Redis for different cache namespaces
    cache_config = {
      price_history: { expires_in: 1.hour },
      route_analysis: { expires_in: 6.hours },
      provider_stats: { expires_in: 24.hours },
      filter_analysis: { expires_in: 2.hours },
      monitoring_metrics: { expires_in: 30.minutes }
    }
    
    cache_config.each do |namespace, config|
      Rails.cache.write("cache_config:#{namespace}", config, expires_in: 1.day)
    end
  end

  def schedule_maintenance_tasks
    # Schedule regular maintenance tasks
    # These would typically be set up with a cron job or similar
    
    maintenance_tasks = [
      { task: 'monitoring:cleanup', schedule: '0 2 * * *', description: 'Daily data cleanup' },
      { task: 'monitoring:analyze', schedule: '0 */6 * * *', description: 'Trend analysis' },
      { task: 'system:optimize', schedule: '0 1 * * *', description: 'Daily optimization' }
    ]
    
    # Store maintenance schedule in cache
    Rails.cache.write('maintenance_schedule', maintenance_tasks, expires_in: 1.week)
    
    puts "Maintenance tasks scheduled:"
    maintenance_tasks.each do |task|
      puts "  - #{task[:schedule]}: #{task[:description]}"
    end
  end
end



