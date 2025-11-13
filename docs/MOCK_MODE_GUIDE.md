# Flight API Mock Mode Guide

## Overview

Your PriceBreak application now has **Mock Mode** enabled by default when no API keys are configured. This allows you to test the entire flight filter system with realistic mock data **without any API costs**.

## How It Works

### Automatic Detection

Mock mode is **automatically enabled** when:
- No API keys are configured (Skyscanner, Amadeus, Google Flights)
- Or explicitly set via `FLIGHT_API_MOCK_MODE=true` environment variable

### Manual Control

Enable/disable mock mode via environment variables:

```bash
# Force enable mock mode (even if API keys exist)
export FLIGHT_API_MOCK_MODE=true

# Disable mock mode (requires API keys)
export FLIGHT_API_MOCK_MODE=false
```

## What Mock Mode Provides

The `MockService` generates realistic flight data including:

✅ **Realistic Prices**: Based on route distance and cabin class  
✅ **Multiple Airlines**: 12 different airlines with proper codes  
✅ **Flight Details**: Departure/arrival times, durations, stops  
✅ **Direct & Connecting**: Mix of direct (60%) and connecting flights  
✅ **Price Variations**: Budget (30%), Normal (40%), Premium (30%) distribution  
✅ **Round Trip Support**: Return flights with proper date handling  
✅ **Price History**: Historical price trends for routes  
✅ **Airport Suggestions**: Common US airports  

## Testing With Mock Mode

### 1. Check Mock Mode Status

```bash
rails flight_api:test
```

You should see:
```
🚀 Flight API Mock Mode: ENABLED (using mock data, no API keys needed)
📊 Flight Aggregator initialized with providers: mock
```

### 2. Test Flight Search

```bash
rails flight_api:fetch[JFK,LAX,2025-02-15]
```

This will generate 10-20 mock flights for JFK → LAX route.

### 3. Create a Filter and Test

1. **Create a filter:**
   - Visit: http://localhost:3000/flight_filters/new
   - Set origin: JFK, destination: LAX
   - Set departure date: 30+ days from today
   - Set target price: $400
   - Save the filter

2. **Test price check:**
   - View filter: http://localhost:3000/flight_filters/:id
   - Click "Test Price Check" button
   - System will generate mock prices and store them

3. **Check results:**
   ```ruby
   # Rails console:
   filter = FlightFilter.last
   FlightPriceHistory.where(route: filter.route_description).order(:timestamp)
   ```

### 4. Test Price Monitoring

```ruby
# Rails console:
filter = FlightFilter.active.first
monitoring = PriceMonitoringService.new
result = monitoring.monitor_single_filter(filter)

# Check if alerts were triggered
filter.flight_alerts.where(status: 'triggered')
```

## Mock Data Characteristics

### Price Generation

- **Base Price**: Calculated from route distance × cabin class multiplier
- **Price Range**: Typically $200-$800 for domestic US routes
- **Distribution**:
  - Budget flights (60-80% of base): 30% of results
  - Normal flights (80-120% of base): 40% of results  
  - Premium flights (120-150% of base): 30% of results

### Route Examples

| Route | Typical Price Range | Duration |
|-------|-------------------|----------|
| JFK → LAX | $350-$650 | 5-6 hours |
| LAX → ORD | $250-$450 | 3-4 hours |
| JFK → SFO | $400-$700 | 6-7 hours |
| ATL → LAX | $300-$550 | 4-5 hours |

### Flight Details

- **Departure Times**: Random between 6 AM - 10 PM
- **Airlines**: American, United, Delta, Southwest, JetBlue, etc.
- **Direct Flights**: ~60% of results
- **Stops**: 0-2 stops for connecting flights
- **Duration**: Calculated from route distance + layover time

## Integration with Real APIs

### Switching to Real APIs

When you're ready to use real APIs:

1. **Get API keys** (see `docs/FLIGHT_API_SETUP_GUIDE.md`)
2. **Add to `.env` file:**
   ```bash
   SKYSCANNER_API_KEY=your_key_here
   AMADEUS_API_KEY=your_key_here
   AMADEUS_API_SECRET=your_secret_here
   ```
3. **Restart server** - Mock mode will automatically disable
4. **Verify:**
   ```bash
   rails flight_api:test
   ```

### Mixed Mode (Mock + Real APIs)

You can also use both:

```bash
# Enable both mock and Skyscanner
export ENABLE_MOCK=true
export SKYSCANNER_API_KEY=your_key_here
export ENABLE_SKYSCANNER=true
```

The aggregator will query both mock and real providers, giving you more results.

## Mock Data Quality

### What's Realistic

✅ Price ranges based on actual route distances  
✅ Proper airline codes and names  
✅ Realistic flight durations  
✅ Mix of direct and connecting flights  
✅ Price variations that simulate real market conditions  
✅ Proper date handling for round trips  

### What's Not Realistic

❌ Actual current prices (these are generated)  
❌ Real-time availability  
❌ Actual booking links (point to example.com)  
❌ Seasonal price variations  
❌ Airline-specific pricing strategies  

**Important:** Mock mode is for **testing the system logic**, not for real price monitoring. For production, you'll need real API keys.

## Troubleshooting

### Mock Mode Not Working

1. **Check logs:**
   ```bash
   tail -f log/development.log | grep -i mock
   ```

2. **Verify configuration:**
   ```ruby
   # Rails console:
   FLIGHT_API_GLOBAL_CONFIG[:mock_mode]
   ```

3. **Check service initialization:**
   ```ruby
   aggregator = FlightApis::AggregatorService.new
   aggregator.mock_mode?
   ```

### No Results Returned

- Check filter parameters are valid
- Verify route format (use IATA codes: JFK, LAX, etc.)
- Check dates are in the future

### Prices Seem Unrealistic

Mock prices are **generated** based on formulas. They're designed to test the system logic, not reflect real prices. For accurate prices, use real API keys.

## Best Practices

1. **Development**: Use mock mode for all testing
2. **Staging**: Use mock mode or limited real API calls
3. **Production**: Always use real APIs with proper rate limiting

## Example Mock Data Output

```json
{
  "id": "mock_JFK_LAX_0_1234567890",
  "price": 387.50,
  "currency": "USD",
  "origin": {
    "code": "JFK",
    "name": "John F. Kennedy International Airport",
    "city": "New York"
  },
  "destination": {
    "code": "LAX",
    "name": "Los Angeles International Airport",
    "city": "Los Angeles"
  },
  "outbound": {
    "departure_date": "2025-02-15T08:30:00Z",
    "arrival_date": "2025-02-15T13:45:00Z",
    "carrier": "American Airlines",
    "direct": true,
    "stops": 0,
    "duration": 315
  },
  "airline": {
    "code": "AA",
    "name": "American Airlines"
  },
  "flight_number": "AA1234",
  "cabin_class": "economy",
  "stops": 0,
  "source": "mock",
  "data_quality_score": 0.92
}
```

## Next Steps

1. ✅ **Test with mock mode** - Verify all features work
2. ✅ **Create filters** - Test the full user flow
3. ✅ **Test price monitoring** - Verify alerts trigger correctly
4. ✅ **Get API keys** - When ready for real data
5. ✅ **Switch to real APIs** - For production use

---

**Mock mode is perfect for development and testing - use it freely!** 🚀
