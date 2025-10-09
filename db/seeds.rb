# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "✈️ Creating international flight demo data for PriceBreak..."

# International Flight Filters - US Hubs to Italy
international_filters = [
  {
    name: "JFK-LGA-EWR to Rome FCO",
    description: "Major NYC area airports to Rome Leonardo da Vinci International",
    origin_airports: ["JFK", "LGA", "EWR"],
    destination_airports: ["FCO"],
    trip_type: "round-trip",
    departure_dates: ["2025-09-20", "2025-09-21", "2025-09-22"],
    return_dates: ["2025-09-28", "2025-09-29", "2025-09-30"],
    flexible_dates: true,
    date_flexibility: 3,
    passenger_details: {
      adults: 2,
      children: 0,
      infants: 0
    },
    price_parameters: {
      target_price: 1200,
      max_price: 2000,
      min_price: 800,
      currency: "USD",
      price_drop_percentage: 15
    },
    advanced_preferences: {
      cabin_class: "premium-economy",
      max_stops: "1-stop",
      airline_preferences: ["Alitalia", "Delta", "American"],
      preferred_times: {
        departure: ["morning", "afternoon"],
        arrival: ["afternoon", "evening"]
      }
    },
    alert_settings: {
      monitor_frequency: "hourly",
      alert_urgency: "urgent",
      notification_methods: {
        email: true,
        push: true,
        sms: false,
        browser: true
      },
      instant_alert_priority: "high"
    },
    is_active: true
  },
  {
    name: "Rome FCO to Florence FLR",
    description: "Internal Italy flight from Rome to Florence",
    origin_airports: ["FCO"],
    destination_airports: ["FLR"],
    trip_type: "round-trip",
    departure_dates: ["2025-10-01"],
    return_dates: ["2025-10-05"],
    flexible_dates: true,
    date_flexibility: 2,
    passenger_details: {
      adults: 2,
      children: 0,
      infants: 0
    },
    price_parameters: {
      target_price: 300,
      max_price: 500,
      min_price: 200,
      currency: "USD",
      price_drop_percentage: 20
    },
    advanced_preferences: {
      cabin_class: "economy",
      max_stops: "nonstop",
      airline_preferences: ["Alitalia", "Ryanair"],
      preferred_times: {
        departure: ["morning"],
        arrival: ["morning"]
      }
    },
    alert_settings: {
      monitor_frequency: "daily",
      alert_urgency: "moderate",
      notification_methods: {
        email: true,
        push: false,
        sms: false,
        browser: true
      },
      instant_alert_priority: "normal"
    },
    is_active: true
  },
  {
    name: "JFK-LGA to Rome FCO Group",
    description: "Group booking from NYC area to Rome",
    origin_airports: ["JFK", "LGA"],
    destination_airports: ["FCO"],
    trip_type: "round-trip",
    departure_dates: ["2025-09-18", "2025-09-19", "2025-09-20"],
    return_dates: ["2025-09-26", "2025-09-27", "2025-09-28"],
    flexible_dates: true,
    date_flexibility: 5,
    passenger_details: {
      adults: 6,
      children: 2,
      infants: 0
    },
    price_parameters: {
      target_price: 800,
      max_price: 1200,
      min_price: 600,
      currency: "USD",
      price_drop_percentage: 10
    },
    advanced_preferences: {
      cabin_class: "economy",
      max_stops: "2+",
      airline_preferences: [],
      preferred_times: {
        departure: ["morning", "afternoon", "evening"],
        arrival: ["afternoon", "evening"]
      }
    },
    alert_settings: {
      monitor_frequency: "daily",
      alert_urgency: "moderate",
      notification_methods: {
        email: true,
        push: true,
        sms: false,
        browser: true
      },
      instant_alert_priority: "normal"
    },
    is_active: true
  },
  {
    name: "LAX-SFO to Florence FLR",
    description: "West Coast major hubs to Florence",
    origin_airports: ["LAX", "SFO"],
    destination_airports: ["FLR"],
    trip_type: "round-trip",
    departure_dates: ["2025-09-17", "2025-09-18"],
    return_dates: ["2025-09-25", "2025-09-26"],
    flexible_dates: true,
    date_flexibility: 3,
    passenger_details: {
      adults: 4,
      children: 0,
      infants: 0
    },
    price_parameters: {
      target_price: 1400,
      max_price: 1800,
      min_price: 1000,
      currency: "USD",
      price_drop_percentage: 12
    },
    advanced_preferences: {
      cabin_class: "economy",
      max_stops: "1-stop",
      airline_preferences: ["United", "American", "Lufthansa"],
      preferred_times: {
        departure: ["evening", "red-eye"],
        arrival: ["morning", "afternoon"]
      }
    },
    alert_settings: {
      monitor_frequency: "hourly",
      alert_urgency: "urgent",
      notification_methods: {
        email: true,
        push: true,
        sms: true,
        browser: true
      },
      instant_alert_priority: "high"
    },
    is_active: true
  },
  {
    name: "ORD-MDW to Rome FCO",
    description: "Chicago area airports to Rome",
    origin_airports: ["ORD", "MDW"],
    destination_airports: ["FCO"],
    trip_type: "round-trip",
    departure_dates: ["2025-09-19"],
    return_dates: ["2025-09-29"],
    flexible_dates: false,
    date_flexibility: 1,
    passenger_details: {
      adults: 3,
      children: 0,
      infants: 0
    },
    price_parameters: {
      target_price: 1100,
      max_price: 1600,
      min_price: 900,
      currency: "USD",
      price_drop_percentage: 18
    },
    advanced_preferences: {
      cabin_class: "premium-economy",
      max_stops: "nonstop",
      airline_preferences: ["United", "Lufthansa"],
      preferred_times: {
        departure: ["afternoon"],
        arrival: ["morning"]
      }
    },
    alert_settings: {
      monitor_frequency: "real-time",
      alert_urgency: "urgent",
      notification_methods: {
        email: true,
        push: true,
        sms: true,
        browser: true
      },
      instant_alert_priority: "critical"
    },
    is_active: true
  },
  {
    name: "PDX to Rome FCO",
    description: "Portland International to Rome",
    origin_airports: ["PDX"],
    destination_airports: ["FCO"],
    trip_type: "round-trip",
    departure_dates: ["2025-09-15", "2025-09-16"],
    return_dates: ["2025-09-25", "2025-09-26"],
    flexible_dates: true,
    date_flexibility: 2,
    passenger_details: {
      adults: 2,
      children: 0,
      infants: 0
    },
    price_parameters: {
      target_price: 1300,
      max_price: 1700,
      min_price: 1000,
      currency: "USD",
      price_drop_percentage: 15
    },
    advanced_preferences: {
      cabin_class: "economy",
      max_stops: "1-stop",
      airline_preferences: ["Alaska", "United", "Lufthansa"],
      preferred_times: {
        departure: ["morning", "afternoon"],
        arrival: ["afternoon", "evening"]
      }
    },
    alert_settings: {
      monitor_frequency: "daily",
      alert_urgency: "moderate",
      notification_methods: {
        email: true,
        push: true,
        sms: false,
        browser: true
      },
      instant_alert_priority: "normal"
    },
    is_active: true
  },
  {
    name: "SEA to Florence FLR",
    description: "Seattle-Tacoma International to Florence",
    origin_airports: ["SEA"],
    destination_airports: ["FLR"],
    trip_type: "round-trip",
    departure_dates: ["2025-09-12", "2025-09-13"],
    return_dates: ["2025-09-22", "2025-09-23"],
    flexible_dates: true,
    date_flexibility: 3,
    passenger_details: {
      adults: 2,
      children: 0,
      infants: 0
    },
    price_parameters: {
      target_price: 1350,
      max_price: 1750,
      min_price: 1100,
      currency: "USD",
      price_drop_percentage: 12
    },
    advanced_preferences: {
      cabin_class: "economy",
      max_stops: "1-stop",
      airline_preferences: ["Alaska", "Delta", "Lufthansa"],
      preferred_times: {
        departure: ["morning", "afternoon"],
        arrival: ["morning", "afternoon"]
      }
    },
    alert_settings: {
      monitor_frequency: "hourly",
      alert_urgency: "urgent",
      notification_methods: {
        email: true,
        push: true,
        sms: true,
        browser: true
      },
      instant_alert_priority: "high"
    },
    is_active: true
  }
]

# Create flight filters
international_filters.each do |filter_data|
  puts "  Creating filter: #{filter_data[:name]}"
  
  FlightFilter.find_or_create_by(name: filter_data[:name]) do |filter|
    filter.description = filter_data[:description]
    filter.origin_airports = filter_data[:origin_airports].to_json
    filter.destination_airports = filter_data[:destination_airports].to_json
    filter.trip_type = filter_data[:trip_type]
    filter.departure_dates = filter_data[:departure_dates].to_json
    filter.return_dates = filter_data[:return_dates].to_json
    filter.flexible_dates = filter_data[:flexible_dates]
    filter.date_flexibility = filter_data[:date_flexibility]
    filter.passenger_details = filter_data[:passenger_details]
    filter.price_parameters = filter_data[:price_parameters]
    filter.advanced_preferences = filter_data[:advanced_preferences]
    filter.alert_settings = filter_data[:alert_settings]
    filter.is_active = filter_data[:is_active]
  end
end

# Create sample flight price history data for Rome/Florence routes
puts "  Creating sample flight price history data..."

price_history_data = [
  # JFK to FCO (Rome)
  { route: "JFK-FCO", date: "2025-09-20", price: 1250, provider: "skyscanner", timestamp: 1.day.ago },
  { route: "JFK-FCO", date: "2025-09-20", price: 1180, provider: "amadeus", timestamp: 2.days.ago },
  { route: "JFK-FCO", date: "2025-09-21", price: 1320, provider: "skyscanner", timestamp: 1.day.ago },
  { route: "JFK-FCO", date: "2025-09-21", price: 1195, provider: "google_flights", timestamp: 3.days.ago },
  
  # LAX to FLR (Florence)
  { route: "LAX-FLR", date: "2025-09-17", price: 1450, provider: "skyscanner", timestamp: 1.day.ago },
  { route: "LAX-FLR", date: "2025-09-17", price: 1380, provider: "amadeus", timestamp: 2.days.ago },
  { route: "LAX-FLR", date: "2025-09-18", price: 1520, provider: "kiwi", timestamp: 1.day.ago },
  
  # ORD to FCO (Rome)
  { route: "ORD-FCO", date: "2025-09-19", price: 1150, provider: "skyscanner", timestamp: 1.day.ago },
  { route: "ORD-FCO", date: "2025-09-19", price: 1080, provider: "united", timestamp: 2.days.ago },
  
  # PDX to FCO (Rome)
  { route: "PDX-FCO", date: "2025-09-15", price: 1350, provider: "alaska", timestamp: 1.day.ago },
  { route: "PDX-FCO", date: "2025-09-15", price: 1280, provider: "united", timestamp: 2.days.ago },
  { route: "PDX-FCO", date: "2025-09-16", price: 1420, provider: "lufthansa", timestamp: 1.day.ago },
  
  # SEA to FLR (Florence)
  { route: "SEA-FLR", date: "2025-09-12", price: 1400, provider: "alaska", timestamp: 1.day.ago },
  { route: "SEA-FLR", date: "2025-09-12", price: 1320, provider: "delta", timestamp: 2.days.ago },
  { route: "SEA-FLR", date: "2025-09-13", price: 1480, provider: "lufthansa", timestamp: 1.day.ago },
  
  # FCO to FLR (Rome to Florence)
  { route: "FCO-FLR", date: "2025-10-01", price: 85, provider: "ryanair", timestamp: 1.day.ago },
  { route: "FCO-FLR", date: "2025-10-01", price: 95, provider: "alitalia", timestamp: 2.days.ago },
  { route: "FCO-FLR", date: "2025-10-02", price: 78, provider: "ryanair", timestamp: 1.day.ago }
]

price_history_data.each do |data|
  FlightPriceHistory.find_or_create_by(
    route: data[:route],
    date: data[:date],
    provider: data[:provider]
  ) do |history|
    history.price = data[:price]
    history.booking_class = "economy"
    history.timestamp = data[:timestamp]
    history.price_validation_status = "valid"
    history.data_quality_score = 0.95
  end
end

# Create sample flight provider data
puts "  Creating sample flight provider data..."

provider_data = [
  {
    flight_identifier: "DL123-JFK-FCO-20250920",
    provider: "delta",
    route: "JFK-FCO",
    schedule: {
      departure_time: "22:30",
      arrival_time: "14:20+1",
      duration: "8h 50m",
      stops: 0,
      aircraft: "Boeing 767"
    },
    pricing: {
      base_price: 1200,
      currency: "USD",
      booking_class: "premium-economy",
      refundable: true,
      baggage_included: true
    },
    data_timestamp: Time.current,
    validation_status: "valid"
  },
  {
    flight_identifier: "AZ456-FCO-FLR-20251001",
    provider: "alitalia",
    route: "FCO-FLR",
    schedule: {
      departure_time: "09:15",
      arrival_time: "10:20",
      duration: "1h 05m",
      stops: 0,
      aircraft: "ATR 72"
    },
    pricing: {
      base_price: 95,
      currency: "USD",
      booking_class: "economy",
      refundable: false,
      baggage_included: false
    },
    data_timestamp: Time.current,
    validation_status: "valid"
  }
]

provider_data.each do |data|
  FlightProviderDatum.find_or_create_by(
    flight_identifier: data[:flight_identifier]
  ) do |provider_datum|
    provider_datum.provider = data[:provider]
    provider_datum.route = data[:route]
    provider_datum.schedule = data[:schedule]
    provider_datum.pricing = data[:pricing]
    provider_datum.data_timestamp = data[:data_timestamp]
    provider_datum.validation_status = data[:validation_status]
  end
end

puts "✅ International flight demo data created successfully!"
puts "   - #{international_filters.count} international flight filters"
puts "   - #{price_history_data.count} price history records"
puts "   - #{provider_data.count} flight provider records"
puts ""
puts "✈️ Ready to demo your international flight monitoring! 🇮🇹"
