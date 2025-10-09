namespace :monitoring do
  desc "Start the flight price monitoring system"
  task start: :environment do
    puts "Starting flight price monitoring system..."
    
    begin
      # Start all monitoring jobs
      FlightPriceMonitoringJob.start_monitoring
      PriceTrendAnalysisJob.start_analysis
      FlightDataCleanupJob.start_cleanup
      
      puts "✅ Monitoring system started successfully"
      puts "  - Price monitoring: Active"
      puts "  - Trend analysis: Active"
      puts "  - Data cleanup: Active"
      
      # Show initial stats
      stats = PriceMonitoringService.monitoring_stats
      puts "\n📊 Initial Stats:"
      puts "  - Active filters: #{stats[:active_filters]}"
      puts "  - Total alerts: #{stats[:total_alerts]}"
      puts "  - System health: #{stats[:system_health]}"
      
    rescue => e
      puts "❌ Failed to start monitoring system: #{e.message}"
      puts e.backtrace.join("\n")
      exit 1
    end
  end

  desc "Stop the flight price monitoring system"
  task stop: :environment do
    puts "Stopping flight price monitoring system..."
    
    begin
      # Stop all monitoring jobs
      FlightPriceMonitoringJob.stop_monitoring
      PriceTrendAnalysisJob.stop_monitoring
      FlightDataCleanupJob.stop_monitoring
      
      puts "✅ Monitoring system stopped successfully"
      
    rescue => e
      puts "❌ Failed to stop monitoring system: #{e.message}"
      puts e.backtrace.join("\n")
      exit 1
    end
  end

  desc "Restart the flight price monitoring system"
  task restart: :environment do
    puts "Restarting flight price monitoring system..."
    
    Rake::Task['monitoring:stop'].invoke
    sleep(2) # Brief pause
    Rake::Task['monitoring:start'].invoke
  end

  desc "Check monitoring system status"
  task status: :environment do
    puts "Flight Price Monitoring System Status"
    puts "=" * 50
    
    # Check if monitoring is running
    monitoring_running = FlightPriceMonitoringJob.where(queue_name: 'monitoring').exists?
    analysis_running = PriceTrendAnalysisJob.where(queue_name: 'analysis').exists?
    cleanup_running = FlightDataCleanupJob.where(queue_name: 'cleanup').exists?
    
    puts "Price Monitoring: #{monitoring_running ? '🟢 Running' : '🔴 Stopped'}"
    puts "Trend Analysis:   #{analysis_running ? '🟢 Running' : '🔴 Stopped'}"
    puts "Data Cleanup:     #{cleanup_running ? '🟢 Running' : '🔴 Stopped'}"
    
    # Show stats
    stats = PriceMonitoringService.monitoring_stats
    puts "\n📊 System Statistics:"
    puts "  - Active filters: #{stats[:active_filters]}"
    puts "  - Total alerts: #{stats[:total_alerts]}"
    puts "  - Triggered alerts: #{stats[:triggered_alerts]}"
    puts "  - Recent price checks: #{stats[:recent_price_checks]}"
    puts "  - System health: #{stats[:system_health]}"
    
    # Show data quality
    quality = FlightDataCleanupJob.data_quality_metrics
    puts "\n📈 Data Quality:"
    puts "  - Price history records: #{quality[:total_price_history]}"
    puts "  - Valid price history: #{quality[:valid_price_history]}"
    puts "  - Provider data records: #{quality[:total_provider_data]}"
    puts "  - Valid provider data: #{quality[:valid_provider_data]}"
    puts "  - Active alerts: #{quality[:active_alerts]}"
  end

  desc "Run a single monitoring cycle"
  task run_once: :environment do
    puts "Running single monitoring cycle..."
    
    begin
      monitoring_service = PriceMonitoringService.new
      result = monitoring_service.monitor_all_filters
      
      if result[:success]
        puts "✅ Monitoring cycle completed successfully"
        puts "  - Filters monitored: #{result[:monitored_count]}"
        puts "  - Alerts triggered: #{result[:alerts_triggered]}"
        puts "  - Price breaks detected: #{result[:price_breaks_detected]}"
        
        if result[:errors].any?
          puts "\n⚠️  Errors encountered:"
          result[:errors].each { |error| puts "  - #{error}" }
        end
      else
        puts "❌ Monitoring cycle failed"
        puts "  - Errors: #{result[:errors].join(', ')}"
      end
      
    rescue => e
      puts "❌ Monitoring cycle failed: #{e.message}"
      puts e.backtrace.join("\n")
      exit 1
    end
  end

  desc "Run a single analysis cycle"
  task analyze: :environment do
    puts "Running single analysis cycle..."
    
    begin
      result = PriceTrendAnalysisJob.new.perform(:full)
      
      if result[:success]
        puts "✅ Analysis cycle completed successfully"
        puts "  - Routes analyzed: #{result[:routes_analyzed]}"
        puts "  - Anomalies detected: #{result[:anomalies_detected]}"
        puts "  - Trends identified: #{result[:trends_identified]}"
        puts "  - Quality improvements: #{result[:data_quality_improvements]}"
        
        if result[:errors].any?
          puts "\n⚠️  Errors encountered:"
          result[:errors].each { |error| puts "  - #{error}" }
        end
      else
        puts "❌ Analysis cycle failed"
        puts "  - Error: #{result[:error]}"
      end
      
    rescue => e
      puts "❌ Analysis cycle failed: #{e.message}"
      puts e.backtrace.join("\n")
      exit 1
    end
  end

  desc "Run a single cleanup cycle"
  task cleanup: :environment do
    puts "Running single cleanup cycle..."
    
    begin
      result = FlightDataCleanupJob.new.perform(:full)
      
      if result[:success]
        puts "✅ Cleanup cycle completed successfully"
        puts "  - Old data removed: #{result[:old_data_removed]}"
        puts "  - Invalid data removed: #{result[:invalid_data_removed]}"
        puts "  - Duplicates removed: #{result[:duplicates_removed]}"
        puts "  - Suspicious data flagged: #{result[:suspicious_data_flagged]}"
        
        if result[:errors].any?
          puts "\n⚠️  Errors encountered:"
          result[:errors].each { |error| puts "  - #{error}" }
        end
      else
        puts "❌ Cleanup cycle failed"
        puts "  - Error: #{result[:error]}"
      end
      
    rescue => e
      puts "❌ Cleanup cycle failed: #{e.message}"
      puts e.backtrace.join("\n")
      exit 1
    end
  end

  desc "Show monitoring configuration"
  task config: :environment do
    puts "Flight Price Monitoring Configuration"
    puts "=" * 50
    
    # Show Sidekiq configuration
    puts "Sidekiq Configuration:"
    puts "  - Concurrency: #{ENV.fetch('SIDEKIQ_CONCURRENCY', 5)}"
    puts "  - Queues: monitoring, alerts, analysis, cleanup, default, mailers"
    puts "  - Timeout: 25 seconds"
    puts "  - Max retries: 3"
    
    # Show monitoring intervals
    puts "\nMonitoring Intervals:"
    puts "  - Full monitoring: Every 2 hours"
    puts "  - Urgent monitoring: Every 30 minutes"
    puts "  - Trend analysis: Every 6 hours"
    puts "  - Data cleanup: Every 24 hours"
    
    # Show filter settings
    puts "\nFilter Settings:"
    puts "  - Max filters per user: Unlimited (for now)"
    puts "  - Min price drop percentage: 5%"
    puts "  - Spam prevention: Enabled"
    puts "  - Quality scoring: Enabled"
    
    # Show notification settings
    puts "\nNotification Settings:"
    puts "  - Email: Enabled"
    puts "  - Push notifications: Enabled"
    puts "  - SMS: Enabled"
    puts "  - Browser notifications: Enabled"
  end

  desc "Reset monitoring system (stop, clear jobs, start)"
  task reset: :environment do
    puts "Resetting monitoring system..."
    
    # Stop monitoring
    Rake::Task['monitoring:stop'].invoke
    
    # Clear all jobs
    puts "Clearing all background jobs..."
    Sidekiq::Queue.new('monitoring').clear
    Sidekiq::Queue.new('alerts').clear
    Sidekiq::Queue.new('analysis').clear
    Sidekiq::Queue.new('cleanup').clear
    
    # Clear cache
    puts "Clearing monitoring cache..."
    Rails.cache.delete('monitoring_metrics')
    Rails.cache.delete('trend_analysis_metrics')
    Rails.cache.delete('cleanup_metrics')
    
    # Start monitoring
    Rake::Task['monitoring:start'].invoke
    
    puts "✅ Monitoring system reset successfully"
  end

  desc "Show help for monitoring tasks"
  task help: :environment do
    puts "Flight Price Monitoring System - Available Tasks"
    puts "=" * 60
    puts ""
    puts "Basic Operations:"
    puts "  rake monitoring:start     - Start the monitoring system"
    puts "  rake monitoring:stop      - Stop the monitoring system"
    puts "  rake monitoring:restart   - Restart the monitoring system"
    puts "  rake monitoring:status    - Show system status"
    puts "  rake monitoring:reset     - Reset the entire system"
    puts ""
    puts "Single Operations:"
    puts "  rake monitoring:run_once  - Run one monitoring cycle"
    puts "  rake monitoring:analyze   - Run one analysis cycle"
    puts "  rake monitoring:cleanup   - Run one cleanup cycle"
    puts ""
    puts "Information:"
    puts "  rake monitoring:config    - Show configuration"
    puts "  rake monitoring:help      - Show this help"
    puts ""
    puts "Examples:"
    puts "  # Start monitoring in production"
    puts "  RAILS_ENV=production rake monitoring:start"
    puts ""
    puts "  # Check status"
    puts "  rake monitoring:status"
    puts ""
    puts "  # Run single check for testing"
    puts "  rake monitoring:run_once"
  end
end



