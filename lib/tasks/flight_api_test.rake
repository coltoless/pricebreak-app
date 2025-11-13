namespace :flight_api do
  desc "Test flight API connections and fetch sample data"
  task test: :environment do
    puts "=" * 60
    puts "Testing Flight API Integration"
    puts "=" * 60
    
    # Check for API keys
    puts "\n📋 API Key Status:"
    puts "-" * 60
    skyscanner_key = ENV['SKYSCANNER_API_KEY'] || Rails.application.credentials.dig(:api_keys, :skyscanner)
    amadeus_key = ENV['AMADEUS_API_KEY'] || Rails.application.credentials.dig(:api_keys, :amadeus)
    amadeus_secret = ENV['AMADEUS_API_SECRET'] || Rails.application.credentials.dig(:api_keys, :amadeus_secret)
    google_key = ENV['GOOGLE_FLIGHTS_API_KEY'] || Rails.application.credentials.dig(:api_keys, :google_flights)
    
    puts "Skyscanner API Key: #{skyscanner_key ? '✅ Present' : '❌ Missing'}"
    puts "Amadeus API Key: #{amadeus_key ? '✅ Present' : '❌ Missing'}"
    puts "Amadeus API Secret: #{amadeus_secret ? '✅ Present' : '❌ Missing'}"
    puts "Google Flights API Key: #{google_key ? '✅ Present' : '❌ Missing (Deprecated API)'}"
    
    if !skyscanner_key && !amadeus_key
      puts "\n⚠️  WARNING: No API keys found!"
      puts "   Set API keys in .env file or Rails credentials"
      puts "   See: docs/FLIGHT_API_SETUP_GUIDE.md"
      exit 1
    end
    
    # Test individual providers
    puts "\n🔍 Testing Individual Providers:"
    puts "-" * 60
    
    test_params = {
      origin: 'JFK',
      destination: 'LAX',
      outbound_date: (Date.today + 30.days).strftime('%Y-%m-%d'),
      adults: 1,
      currency: 'USD'
    }
    
    # Test Skyscanner
    if skyscanner_key
      puts "\n1. Testing Skyscanner..."
      begin
        skyscanner = FlightApis::SkyscannerService.new
        results = skyscanner.search_flights(test_params)
        if results.is_a?(Array) && results.any?
          puts "   ✅ Success: Found #{results.count} flights"
          puts "   💰 Lowest price: $#{results.map { |r| r[:price] }.compact.min || 'N/A'}"
        else
          puts "   ⚠️  No results returned (API may need authentication or has rate limits)"
        end
      rescue => e
        puts "   ❌ Error: #{e.message}"
      end
    else
      puts "\n1. Skyscanner: ⏭️  Skipped (no API key)"
    end
    
    # Test Amadeus
    if amadeus_key && amadeus_secret
      puts "\n2. Testing Amadeus..."
      begin
        amadeus = FlightApis::AmadeusService.new
        results = amadeus.search_flights({
          origin: 'JFK',
          destination: 'LAX',
          departure_date: (Date.today + 30.days).strftime('%Y-%m-%d'),
          adults: 1,
          currency: 'USD'
        })
        if results.is_a?(Array) && results.any?
          puts "   ✅ Success: Found #{results.count} flights"
          puts "   💰 Lowest price: $#{results.map { |r| r[:price] }.compact.min || 'N/A'}"
        else
          puts "   ⚠️  No results returned (check authentication)"
        end
      rescue => e
        puts "   ❌ Error: #{e.message}"
      end
    else
      puts "\n2. Amadeus: ⏭️  Skipped (no API key/secret)"
    end
    
    # Test Aggregator
    puts "\n3. Testing Aggregator Service..."
    begin
      aggregator = FlightApis::AggregatorService.new
      result = aggregator.search_all(test_params)
      
      if result[:success]
        puts "   ✅ Success: #{result[:total_count]} total results"
        puts "   📊 Providers queried: #{result[:providers_queried].join(', ')}"
        puts "   🎯 Strategy: #{result[:search_strategy]}"
        
        if result[:results].any?
          prices = result[:results].map { |r| r[:price] }.compact
          if prices.any?
            puts "   💰 Price range: $#{prices.min} - $#{prices.max}"
            puts "   📈 Average: $#{(prices.sum / prices.length).round(2)}"
          end
        end
        
        if result[:errors].any?
          puts "   ⚠️  Errors: #{result[:errors].join('; ')}"
        end
      else
        puts "   ❌ Failed: #{result[:errors].join('; ')}"
      end
    rescue => e
      puts "   ❌ Error: #{e.message}"
      puts "   📝 #{e.backtrace.first}"
    end
    
    # Test Price Monitoring
    puts "\n4. Testing Price Monitoring Service..."
    begin
      # Use an existing filter or create a test one
      filter = FlightFilter.active.first
      
      if filter
        puts "   📋 Using filter: #{filter.name} (#{filter.route_description})"
        monitoring = PriceMonitoringService.new
        result = monitoring.monitor_single_filter(filter)
        
        puts "   ✅ Monitoring completed"
        
        # Check price history
        history = FlightPriceHistory.where(route: filter.route_description)
                                   .order(timestamp: :desc)
                                   .limit(5)
        
        if history.any?
          puts "   📊 Latest prices stored: #{history.count} records"
        else
          puts "   ⚠️  No price history stored yet"
        end
        
        # Check alerts
        alerts = filter.flight_alerts.where(status: 'triggered')
        if alerts.any?
          puts "   🔔 Active alerts: #{alerts.count}"
        end
      else
        puts "   ⏭️  Skipped: No active filters found"
        puts "   💡 Create a filter at: http://localhost:3000/flight_filters/new"
      end
    rescue => e
      puts "   ❌ Error: #{e.message}"
    end
    
    puts "\n" + "=" * 60
    puts "✅ Test Complete!"
    puts "=" * 60
    puts "\n📚 Next Steps:"
    puts "1. If API keys are missing, see: docs/FLIGHT_API_SETUP_GUIDE.md"
    puts "2. Create a filter at: http://localhost:3000/flight_filters/new"
    puts "3. Test price check: POST /flight_filters/:id/test_price_check"
    puts "4. View dashboard: http://localhost:3000/dashboard"
    puts ""
  end
  
  desc "Fetch real-time prices for a specific route"
  task :fetch, [:origin, :destination, :date] => :environment do |t, args|
    origin = args[:origin] || 'JFK'
    destination = args[:destination] || 'LAX'
    date = args[:date] || (Date.today + 30.days).strftime('%Y-%m-%d')
    
    puts "Fetching flights: #{origin} → #{destination} on #{date}"
    puts "-" * 60
    
    aggregator = FlightApis::AggregatorService.new
    result = aggregator.search_all({
      origin: origin,
      destination: destination,
      outbound_date: date,
      adults: 1,
      currency: 'USD',
      sort_by: 'price'
    })
    
    if result[:success] && result[:results].any?
      puts "\n✅ Found #{result[:total_count]} flights:\n\n"
      
      result[:results].first(10).each_with_index do |flight, index|
        puts "#{index + 1}. #{flight[:origin][:code]} → #{flight[:destination][:code]}"
        puts "   Price: $#{flight[:price]}"
        puts "   Provider: #{flight[:source]}"
        puts "   Direct: #{flight[:outbound] && flight[:outbound][:direct] ? 'Yes' : 'No'}"
        puts ""
      end
      
      # Store in database
      flight_provider_data = result[:results].map do |flight|
        FlightProviderDatum.create!(
          flight_identifier: flight[:id] || SecureRandom.hex(10),
          provider: flight[:source] || 'unknown',
          route: "#{flight[:origin][:code]}-#{flight[:destination][:code]}",
          schedule: {
            departure: flight[:outbound]&.dig(:departure_date),
            arrival: flight[:outbound]&.dig(:arrival_date)
          },
          pricing: {
            price: flight[:price],
            currency: flight[:currency] || 'USD'
          },
          data_timestamp: Time.current,
          validation_status: 'valid'
        )
      end
      
      puts "💾 Stored #{flight_provider_data.count} flights in database"
    else
      puts "❌ No flights found or API error"
      if result[:errors].any?
        puts "Errors: #{result[:errors].join(', ')}"
      end
    end
  end
end

