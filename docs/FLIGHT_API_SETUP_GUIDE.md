# Flight API Setup Guide - Real-Time Data Integration

## Overview

Your PriceBreak application has a **complete multi-provider flight data aggregation system** ready to pull real-time flight prices from:

1. **Skyscanner** (Primary - Browse Quotes API)
2. **Amadeus** (Professional - Flight Offers API)  
3. **Google Flights** (Price Comparison - QPX Express API)

The system automatically:
- ✅ Aggregates data from all providers
- ✅ Normalizes responses into a unified format
- ✅ Detects and merges duplicate flights
- ✅ Handles rate limiting and fallback strategies
- ✅ Stores prices in `flight_price_histories` table
- ✅ Triggers alerts when prices drop

## Current Status

**What's Already Built:**
- ✅ Multi-provider aggregator service
- ✅ Individual provider services (Skyscanner, Amadeus, Google Flights)
- ✅ Data normalization and deduplication
- ✅ Rate limiting per provider
- ✅ Price monitoring service that uses real APIs
- ✅ Background jobs for continuous monitoring
- ✅ Price history storage

**What Needs Configuration:**
- ⚠️ API keys for each provider (set as environment variables)
- ⚠️ API credentials stored securely

---

## Step 1: Get API Keys

### Skyscanner API Key

1. Go to [Skyscanner Partners Portal](https://developers.skyscanner.net/)
2. Sign up for a free account
3. Create a new application
4. Get your **Rapid API Key** (they use RapidAPI now)
5. Or use their Browse Quotes API directly

**Rate Limits:**
- Free tier: Limited requests per day
- Commercial: $0.001 per request

### Amadeus API Key

1. Go to [Amadeus for Developers](https://developers.amadeus.com/)
2. Create a free account
3. Create a new app in the "My Self-Service Workspace"
4. Get your **API Key** and **API Secret**

**Rate Limits:**
- Test environment: Unlimited (with restrictions)
- Production: Based on your plan

### Google Flights API (QPX Express)

⚠️ **Note:** Google QPX Express API was deprecated in 2018. Consider alternatives:
- Use Google Flights scraping (requires different approach)
- Use alternative providers like:
  - **Kiwi.com API** (already in codebase)
  - **Expedia API**
  - **Kayak API**

---

## Step 2: Configure Environment Variables

Add these to your `.env` file in the project root:

```bash
# Skyscanner API
SKYSCANNER_API_KEY=your_skyscanner_api_key_here

# Amadeus API  
AMADEUS_API_KEY=your_amadeus_api_key_here
AMADEUS_API_SECRET=your_amadeus_api_secret_here

# Google Flights (if available)
GOOGLE_FLIGHTS_API_KEY=your_google_flights_api_key_here

# Alternative: Kiwi.com
KIWI_API_KEY=your_kiwi_api_key_here
```

Or add to Rails credentials (for production):

```bash
rails credentials:edit
```

Add:
```yaml
api_keys:
  skyscanner: your_skyscanner_api_key_here
  amadeus: your_amadeus_api_key_here
  amadeus_secret: your_amadeus_api_secret_here
  google_flights: your_google_flights_api_key_here
```

---

## Step 3: Test the API Integration

### Quick Test Script

Create a test script to verify API connections:

```ruby
# test_flight_apis.rb - Run with: rails runner test_flight_apis.rb

puts "Testing Flight API Integration..."
puts "=" * 50

# Test Skyscanner
puts "\n1. Testing Skyscanner..."
begin
  skyscanner = FlightApis::SkyscannerService.new
  results = skyscanner.search_flights({
    origin: 'JFK',
    destination: 'LAX',
    outbound_date: (Date.today + 30.days).strftime('%Y-%m-%d'),
    adults: 1,
    currency: 'USD'
  })
  puts "✅ Skyscanner: #{results.count} results"
rescue => e
  puts "❌ Skyscanner Error: #{e.message}"
end

# Test Amadeus
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
  puts "✅ Amadeus: #{results.count} results"
rescue => e
  puts "❌ Amadeus Error: #{e.message}"
end

# Test Aggregator
puts "\n3. Testing Aggregator Service..."
begin
  aggregator = FlightApis::AggregatorService.new
  result = aggregator.search_all({
    origin: 'JFK',
    destination: 'LAX',
    outbound_date: (Date.today + 30.days).strftime('%Y-%m-%d'),
    adults: 1,
    currency: 'USD',
    sort_by: 'price'
  })
  
  if result[:success]
    puts "✅ Aggregator: #{result[:total_count]} total results"
    puts "   Providers queried: #{result[:providers_queried].join(', ')}"
    puts "   Strategy: #{result[:search_strategy]}"
    if result[:errors].any?
      puts "   ⚠️ Errors: #{result[:errors].join(', ')}"
    end
  else
    puts "❌ Aggregator Error: #{result[:errors].join(', ')}"
  end
rescue => e
  puts "❌ Aggregator Error: #{e.message}"
end

puts "\n" + "=" * 50
puts "Test Complete!"
```

---

## Step 4: How the Real-Time System Works

### Architecture Flow

```
Flight Filter Created
    ↓
PriceMonitoringService monitors filter
    ↓
AggregatorService.search_all() called
    ↓
├─→ SkyscannerService.search_flights()
├─→ AmadeusService.search_flights()  
└─→ GoogleFlightsService.search_flights()
    ↓
Data Normalizer unifies formats
    ↓
Duplicate Detector merges identical flights
    ↓
PriceBreakDetectionService analyzes prices
    ↓
If price drops → Alert triggered
    ↓
Store in flight_price_histories
```

### Usage Example

```ruby
# In your controller or job:
filter = FlightFilter.find(1)

# The PriceMonitoringService automatically:
# 1. Fetches current prices from all providers
# 2. Compares to filter's target price
# 3. Triggers alerts if price drops
monitoring_service = PriceMonitoringService.new
monitoring_service.monitor_single_filter(filter)

# Or monitor all active filters:
monitoring_service.monitor_all_filters
```

### Background Job (Already Set Up)

The system automatically monitors filters via:

```ruby
# This job runs continuously (via Sidekiq)
FlightPriceMonitoringJob.perform_later(:full)

# Or urgent filters only:
FlightPriceMonitoringJob.perform_later(:urgent_only)
```

---

## Step 5: Using Real-Time Data in Filters

### Create a Filter and Test

1. **Create a filter via UI:**
   - Visit: http://localhost:3000/flight_filters/new
   - Set route, dates, target price
   - Save the filter

2. **Manually trigger price check:**
   ```ruby
   # Rails console:
   filter = FlightFilter.last
   monitoring = PriceMonitoringService.new
   monitoring.monitor_single_filter(filter)
   ```

3. **Check results:**
   ```ruby
   # View price history:
   FlightPriceHistory.where(route: filter.route_description).order(:timestamp)
   
   # View triggered alerts:
   filter.flight_alerts.where(status: 'triggered')
   ```

### API Endpoint to Test

Create a test endpoint (or use Rails console):

```ruby
# Add to flight_filters_controller.rb
def test_price_check
  @flight_filter = FlightFilter.find(params[:id])
  monitoring = PriceMonitoringService.new
  
  result = monitoring.monitor_single_filter(@flight_filter)
  
  render json: {
    success: true,
    filter_id: @flight_filter.id,
    route: @flight_filter.route_description,
    message: "Price check completed. Check flight_price_histories and flight_alerts tables."
  }
end
```

---

## Step 6: Monitor System Status

### Check Provider Health

```ruby
aggregator = FlightApis::AggregatorService.new
health = aggregator.get_provider_health_status
# Returns rate limit status for each provider
```

### View Monitoring Dashboard

Visit: http://localhost:3000/monitoring/dashboard

Shows:
- Active filters being monitored
- Recent price checks
- Alerts triggered
- API provider health
- System performance metrics

---

## Troubleshooting

### No Results Returned

**Check:**
1. API keys are set correctly
2. API keys have proper permissions
3. Rate limits haven't been exceeded
4. Network connectivity

**Debug:**
```ruby
# Check if API keys are loaded:
ENV['SKYSCANNER_API_KEY'] # Should not be nil
ENV['AMADEUS_API_KEY']     # Should not be nil

# Check provider health:
aggregator = FlightApis::AggregatorService.new
aggregator.get_provider_health_status
```

### Rate Limit Errors

The system automatically handles rate limits via `RateLimiterService`. If you see errors:

1. Check your API tier/plan limits
2. Adjust rate limits in `config/initializers/flight_apis.rb`
3. Use cascade strategy instead of parallel (slower but more reliable)

### Authentication Errors (Amadeus)

Amadeus requires OAuth2 authentication. The service handles this automatically, but if failing:

1. Verify API key and secret are correct
2. Check if you're using test vs production URLs
3. Verify your Amadeus account is active

---

## Alternative: Using Mock Data (Development Only)

If you want to test without API keys first:

The system can work with mock data. Check `app/services/flight_apis/` for mock implementations or create a mock service.

---

## Next Steps

1. ✅ Get API keys from providers
2. ✅ Add to `.env` file
3. ✅ Test with the test script above
4. ✅ Create a flight filter
5. ✅ Trigger manual price check
6. ✅ Verify data in `flight_price_histories` table
7. ✅ Set up automatic monitoring via Sidekiq

---

## Production Considerations

1. **API Costs**: Monitor usage and costs per provider
2. **Rate Limiting**: Adjust based on your API tier
3. **Caching**: System already caches responses (see `CacheService`)
4. **Error Handling**: All services have comprehensive error handling
5. **Fallback Strategy**: Configure in `FLIGHT_API_GLOBAL_CONFIG`

---

**Your system is ready - just needs API keys configured!** 🚀

