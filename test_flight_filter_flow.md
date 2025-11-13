# Flight Filter End-to-End Test Checklist

## Test Flow: Complete Filter Creation

### Prerequisites
- User is logged in (or use Devise authentication)
- Server is running: `bin/rails server`
- JavaScript is built: `npm run build`

### Step 1: Navigate to Filter Creation
1. Go to: `http://localhost:3000/flight_filters/new`
2. ✅ Verify the form loads with Step 1 visible
3. ✅ Verify step indicator shows 4 steps

### Step 2: Route & Dates (Step 1)
1. Select trip type: One-way, Round-trip, or Multi-city
2. ✅ Select origin airport (e.g., LAX)
3. ✅ Select destination airport (e.g., JFK)
4. ✅ Select departure date (future date)
5. ✅ If round-trip, select return date (after departure)
6. ✅ Toggle flexible dates if needed
7. Click "Continue"
8. ✅ Verify step 2 loads

### Step 3: Flight Preferences (Step 2)
1. ✅ Select cabin class (Economy, Premium Economy, Business, First)
2. ✅ Adjust passenger counts (adults, children, infants)
3. ✅ Select max stops (Nonstop, 1 stop, 2+)
4. ✅ Select preferred departure/arrival times
5. ✅ (Optional) Select preferred airlines
6. Click "Continue"
7. ✅ Verify step 3 loads

### Step 4: Price Settings (Step 3)
1. ✅ Enter target price (e.g., $500)
2. ✅ Select currency (USD, EUR, etc.)
3. ✅ Toggle instant price break alerts
4. ✅ Adjust price drop percentage (5-50%)
5. ✅ Select price break confidence level
6. Click "Continue"
7. ✅ Verify step 4 loads

### Step 5: Alert Preferences (Step 4)
1. ✅ Select monitoring frequency (Real-time, Hourly, Daily, Weekly)
2. ✅ Select alert urgency (Patient, Moderate, Urgent)
3. ✅ Select instant alert priority (if enabled)
4. ✅ Select alert detail level
5. ✅ Select notification methods (Email, SMS, Push, Browser)
6. ✅ Enter filter name (required)
7. ✅ Enter description (optional)
8. ✅ Verify all settings are displayed correctly

### Step 6: Preview Alert
1. Click "Preview Alert" button
2. ✅ Verify modal opens
3. ✅ Verify preview shows:
   - Route information
   - Departure date
   - Target price vs current price
   - Savings amount and percentage
   - Urgency level
   - Notification methods
   - Alert settings summary
4. Close modal

### Step 7: Test Alert
1. Click "Test Alert" button
2. ✅ Verify loading indicator appears
3. ✅ Verify filter is saved (if new)
4. ✅ Verify test request is sent to backend
5. ✅ Verify results notification appears
6. ✅ Verify results show:
   - Route
   - Latest prices found
   - Alerts triggered count

### Step 8: Save Filter
1. Click "Create Price Alert" button
2. ✅ Verify form validation passes
3. ✅ Verify filter is saved to database
4. ✅ Verify redirect to filter show page
5. ✅ Verify filter appears in filter list

### Step 9: Verify Database
1. Check Rails console: `rails console`
2. Run: `FlightFilter.last`
3. ✅ Verify all fields are saved correctly:
   - `name` matches filter name
   - `origin_airports` contains airport codes
   - `destination_airports` contains airport codes
   - `trip_type` is correct
   - `departure_dates` contains dates
   - `passenger_details` contains passenger counts
   - `price_parameters` contains target price
   - `advanced_preferences` contains cabin class, stops, etc.
   - `alert_settings` contains monitoring frequency
   - `user_id` is set (not null)
4. ✅ Verify associated FlightAlert is created

### Step 10: Edit Filter
1. Navigate to filter show page
2. Click "Edit"
3. ✅ Verify form loads with existing data
4. Make changes
5. Save
6. ✅ Verify changes are saved

## Expected Results

### Success Criteria
- ✅ All 4 steps complete without errors
- ✅ Preview alert shows realistic mock data
- ✅ Test alert successfully calls backend
- ✅ Filter saves to database with all fields
- ✅ User can navigate between steps
- ✅ Validation errors show correctly
- ✅ Filter summary updates as user progresses

### Common Issues to Check
- JavaScript console errors
- Network request failures
- Database constraint violations
- Missing required fields
- Invalid date formats
- Missing airport selections

## API Endpoints Tested

1. `POST /flight_filters` - Create filter
2. `POST /flight_filters/:id/test_price_check` - Test alert
3. `GET /flight_filters/:id` - View filter
4. `PATCH /flight_filters/:id` - Update filter

## Notes
- Mock mode is enabled for testing without API keys
- Test alert uses PriceMonitoringService which may take a few seconds
- Preview alert shows mock price data (15% drop example)
- All form data is validated before submission

