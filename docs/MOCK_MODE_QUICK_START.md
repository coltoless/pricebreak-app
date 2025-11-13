# Mock Mode Quick Start Guide

## ✅ Mock Mode is Now Active!

Your system is **automatically using mock data** because no API keys are configured. This means you can test the entire flight filter system **without any costs**.

## Quick Test

### 1. Test API Connection

```bash
rails flight_api:test
```

**Expected Output:**
```
🚀 Flight API Mock Mode: ENABLED (using mock data, no API keys needed)
📊 Flight Aggregator initialized with providers: mock
✅ Mock service: 19 flights
```

### 2. Create a Flight Filter

1. Visit: http://localhost:3000/flight_filters/new
2. Fill in:
   - **Name**: "JFK to LAX Test"
   - **Origin**: JFK (or type "New York")
   - **Destination**: LAX (or type "Los Angeles")
   - **Departure Date**: 30+ days from today
   - **Target Price**: $400
   - Save

### 3. Test Price Check

1. View your filter: http://localhost:3000/flight_filters/:id
2. Click **"Test Price Check"** button (purple button in Quick Actions)
3. System will:
   - Generate 10-20 mock flights
   - Compare prices to your target
   - Store price history
   - Trigger alerts if price drops below target

### 4. View Results

Check the Rails console or database:

```ruby
# In Rails console:
filter = FlightFilter.last

# View price history
FlightPriceHistory.where(route: filter.route_description).order(:timestamp)

# View triggered alerts
filter.flight_alerts.where(status: 'triggered')
```

## What Mock Data Looks Like

Mock flights include:
- **Prices**: $200-$800 (realistic for domestic US routes)
- **Airlines**: American, United, Delta, Southwest, etc.
- **Flight Times**: Random between 6 AM - 10 PM
- **Direct/Connecting**: Mix of both (60% direct)
- **Durations**: Based on route distance (e.g., JFK→LAX = ~5 hours)

## Example Mock Flight

```json
{
  "price": 387.50,
  "origin": {"code": "JFK", "city": "New York"},
  "destination": {"code": "LAX", "city": "Los Angeles"},
  "outbound": {
    "departure_date": "2025-02-15T08:30:00Z",
    "carrier": "American Airlines",
    "direct": true
  },
  "airline": {"code": "AA", "name": "American Airlines"},
  "source": "mock"
}
```

## Switching to Real APIs

When ready to use real data:

1. Get API keys (see `docs/FLIGHT_API_SETUP_GUIDE.md`)
2. Add to `.env`:
   ```bash
   SKYSCANNER_API_KEY=your_key
   AMADEUS_API_KEY=your_key
   AMADEUS_API_SECRET=your_secret
   ```
3. Restart server - mock mode will auto-disable

## Troubleshooting

**No results returned?**
- Check filter parameters are valid
- Use proper airport codes (JFK, LAX, ORD, etc.)
- Ensure departure date is in the future

**Prices seem off?**
- Mock prices are generated, not real
- They're designed for testing system logic
- Use real APIs for accurate prices

**Alert not triggering?**
- Ensure target price is realistic ($300-$500 for domestic)
- Check spam prevention settings
- Mock prices vary randomly

---

**You're all set! Mock mode is working - start testing!** 🎉

