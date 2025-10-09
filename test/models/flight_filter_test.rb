require 'test_helper'

class FlightFilterTest < ActiveSupport::TestCase
  def setup
    @valid_filter_params = {
      name: "Test Flight Filter",
      description: "A test filter for testing",
      origin_airports: ["LAX"],
      destination_airports: ["JFK"],
      trip_type: "round-trip",
      departure_dates: ["2025-12-25"],
      return_dates: ["2025-12-30"],
      passenger_details: { "adults" => 2, "children" => 1, "infants" => 0 },
      price_parameters: { "target_price" => 500, "max_price" => 1000, "min_price" => 200 },
      advanced_preferences: { "cabin_class" => "economy", "max_stops" => "1-stop", "airline_preferences" => [] },
      alert_settings: { "monitor_frequency" => "daily", "notification_methods" => { "email" => true } }
    }
  end

  test "should create a valid flight filter without user (Phase 1)" do
    filter = FlightFilter.new(@valid_filter_params)
    assert filter.valid?
    assert filter.save
  end

  test "should require name" do
    filter = FlightFilter.new(@valid_filter_params.except(:name))
    assert_not filter.valid?
    assert_includes filter.errors[:name], "can't be blank"
  end

  test "should require origin airports" do
    filter = FlightFilter.new(@valid_filter_params.except(:origin_airports))
    assert_not filter.valid?
    assert_includes filter.errors[:origin_airports], "can't be blank"
  end

  test "should require destination airports" do
    filter = FlightFilter.new(@valid_filter_params.except(:destination_airports))
    assert_not filter.valid?
    assert_includes filter.errors[:destination_airports], "can't be blank"
  end

  test "should validate trip type" do
    filter = FlightFilter.new(@valid_filter_params.merge(trip_type: "invalid_type"))
    assert_not filter.valid?
    assert_includes filter.errors[:trip_type], "is not included in the list"
  end

  test "should validate passenger details" do
    # Test with no adults
    filter = FlightFilter.new(@valid_filter_params.merge(
      passenger_details: { "adults" => 0, "children" => 1, "infants" => 0 }
    ))
    assert_not filter.valid?
    assert_includes filter.errors[:passenger_details], "must have at least one adult"
  end

  test "should validate price parameters" do
    # Test with min_price >= max_price
    filter = FlightFilter.new(@valid_filter_params.merge(
      price_parameters: { "target_price" => 500, "max_price" => 200, "min_price" => 300 }
    ))
    assert_not filter.valid?
    assert_includes filter.errors[:price_parameters], "minimum price must be less than maximum price"
  end

  test "should validate advanced preferences" do
    # Test with invalid cabin class
    filter = FlightFilter.new(@valid_filter_params.merge(
      advanced_preferences: { "cabin_class" => "invalid_class", "max_stops" => "1-stop" }
    ))
    assert_not filter.valid?
    assert_includes filter.errors[:advanced_preferences], "invalid cabin class"
  end

  test "should validate alert settings" do
    # Test with invalid monitor frequency
    filter = FlightFilter.new(@valid_filter_params.merge(
      alert_settings: { "monitor_frequency" => "invalid_frequency", "notification_methods" => { "email" => true } }
    ))
    assert_not filter.valid?
    assert_includes filter.errors[:alert_settings], "invalid monitor frequency"
  end

  test "should set defaults correctly" do
    filter = FlightFilter.new(@valid_filter_params.except(:passenger_details, :price_parameters, :advanced_preferences, :alert_settings))
    filter.valid? # Trigger before_validation callbacks
    
    assert_equal({ "adults" => 1, "children" => 0, "infants" => 0 }, filter.passenger_details)
    assert_equal({ "target_price" => 0, "max_price" => 10000, "min_price" => 0 }, filter.price_parameters)
    assert_equal({ "cabin_class" => "economy", "max_stops" => "any", "airline_preferences" => [] }, filter.advanced_preferences)
    assert_equal({ "monitor_frequency" => "daily", "notification_methods" => { "email" => true } }, filter.alert_settings)
    assert filter.is_active
    assert_equal 3, filter.date_flexibility
  end

  test "should handle array methods correctly" do
    filter = FlightFilter.new(@valid_filter_params)
    filter.save!
    
    assert_equal ["LAX"], filter.origin_airports_array
    assert_equal ["JFK"], filter.destination_airports_array
    assert_equal ["2025-12-25"], filter.departure_dates_array
    assert_equal ["2025-12-30"], filter.return_dates_array
  end

  test "should generate route description" do
    filter = FlightFilter.new(@valid_filter_params)
    assert_equal "LAX → JFK", filter.route_description
  end

  test "should calculate passenger count" do
    filter = FlightFilter.new(@valid_filter_params)
    assert_equal 3, filter.passenger_count
  end

  test "should determine if urgent" do
    # Test with future date (not urgent)
    filter = FlightFilter.new(@valid_filter_params.merge(
      departure_dates: ["2025-12-25"]
    ))
    assert_not filter.is_urgent?
    
    # Test with near future date (urgent)
    filter = FlightFilter.new(@valid_filter_params.merge(
      departure_dates: [(Date.current + 20.days).to_s]
    ))
    assert filter.is_urgent?
  end

  test "should determine monitoring frequency" do
    # Test with urgent filter (should monitor frequently)
    filter = FlightFilter.new(@valid_filter_params.merge(
      departure_dates: [(Date.current + 20.days).to_s]
    ))
    assert filter.should_monitor_frequently?
    
    # Test with non-urgent filter
    filter = FlightFilter.new(@valid_filter_params.merge(
      departure_dates: ["2025-12-25"]
    ))
    assert_not filter.should_monitor_frequently?
  end

  test "should activate and deactivate" do
    filter = FlightFilter.create!(@valid_filter_params)
    assert filter.is_active
    
    filter.deactivate!
    assert_not filter.is_active
    
    filter.activate!
    assert filter.is_active
  end

  test "should detect duplicates" do
    filter1 = FlightFilter.create!(@valid_filter_params)
    filter2 = FlightFilter.create!(@valid_filter_params.merge(name: "Duplicate Filter"))
    
    assert filter1.duplicate?
    assert filter2.duplicate?
  end

  test "should work with fixtures" do
    # Test that fixtures load correctly
    assert_equal 3, FlightFilter.count
    assert FlightFilter.find_by(name: "Test Flight Filter 1")
    assert FlightFilter.find_by(name: "Test Flight Filter 2")
    assert FlightFilter.find_by(name: "Test Flight Filter 3 (No User)")
  end

  test "should handle JSON field parsing errors gracefully" do
    # Test with malformed JSON
    filter = FlightFilter.new(@valid_filter_params.merge(
      origin_airports: "invalid json string"
    ))
    
    # Should handle gracefully and return empty array
    assert_equal [], filter.origin_airports_array
  end
end
