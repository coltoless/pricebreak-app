module FlightApis
  class SkyscannerService < BaseApiService
    def search_flights(params = {})
      endpoint = '/flights/browse/v1.0/US/USD/en-US'
      response = make_request(endpoint, build_flight_params(params))
      transform_flights(response['Quotes'], response['Places'], response['Carriers'])
    end

    def get_flight_details(flight_id)
      endpoint = "/flights/browse/v1.0/US/USD/en-US/#{flight_id}"
      response = make_request(endpoint)
      transform_flight_details(response)
    end

    def search_wedding_packages(wedding_date, destination, guest_count = 1)
      # Wedding-specific search with flexible dates around the wedding
      search_params = {
        origin: 'US', # Default to US, can be made configurable
        destination: destination,
        outbound_date: (wedding_date - 2.days).strftime('%Y-%m-%d'),
        inbound_date: (wedding_date + 2.days).strftime('%Y-%m-%d'),
        adults: guest_count,
        cabin_class: 'economy',
        currency: 'USD'
      }
      
      search_flights(search_params)
    end

    private

    def api_key_name
      :skyscanner
    end

    def base_url
      'https://partners.api.skyscanner.net'
    end

    def build_flight_params(params)
      {
        origin: params[:origin] || 'US',
        destination: params[:destination],
        outbound_date: params[:outbound_date] || params[:departure_date],
        inbound_date: params[:inbound_date] || params[:return_date],
        adults: params[:adults] || params[:passengers] || 1,
        children: params[:children] || 0,
        infants: params[:infants] || 0,
        cabin_class: params[:cabin_class] || 'economy',
        currency: params[:currency] || 'USD',
        locale: params[:locale] || 'en-US'
      }.compact
    end

    def transform_flights(quotes, places, carriers)
      return [] unless quotes

      quotes.map do |quote|
        origin_place = places.find { |p| p['PlaceId'] == quote['OutboundLeg']['OriginId'] }
        destination_place = places.find { |p| p['PlaceId'] == quote['OutboundLeg']['DestinationId'] }
        carrier = carriers.find { |c| c['CarrierId'] == quote['OutboundLeg']['CarrierIds'].first }

        {
          id: quote['QuoteId'],
          price: quote['MinPrice'],
          currency: 'USD',
          origin: {
            code: origin_place['IataCode'],
            name: origin_place['Name'],
            city: origin_place['CityName']
          },
          destination: {
            code: destination_place['IataCode'],
            name: destination_place['Name'],
            city: destination_place['CityName']
          },
          outbound: {
            departure_date: quote['OutboundLeg']['DepartureDate'],
            carrier: carrier['Name'],
            direct: quote['OutboundLeg']['CarrierIds'].length == 1
          },
          inbound: quote['InboundLeg'] ? {
            departure_date: quote['InboundLeg']['DepartureDate'],
            carrier: carriers.find { |c| c['CarrierId'] == quote['InboundLeg']['CarrierIds'].first }&.dig('Name'),
            direct: quote['InboundLeg']['CarrierIds'].length == 1
          } : nil,
          booking_link: generate_booking_link(quote['QuoteId']),
          source: 'skyscanner',
          wedding_optimized: is_wedding_optimized?(quote)
        }
      end
    end

    def transform_flight_details(flight_data)
      # Enhanced flight details for wedding planning
      {
        id: flight_data['QuoteId'],
        price: flight_data['MinPrice'],
        currency: 'USD',
        route_details: flight_data['Routes'],
        booking_options: flight_data['BookingOptions'],
        wedding_features: {
          flexible_dates: flight_data['FlexibleDates'],
          group_booking_available: flight_data['GroupBookingAvailable'],
          cancellation_policy: flight_data['CancellationPolicy']
        },
        source: 'skyscanner'
      }
    end

    def generate_booking_link(quote_id)
      "https://www.skyscanner.com/transport/flights/#{quote_id}"
    end

    def is_wedding_optimized?(quote)
      # Check if this flight is optimal for wedding travel
      # Consider factors like timing, price, and convenience
      price = quote['MinPrice']
      departure_date = Date.parse(quote['OutboundLeg']['DepartureDate'])
      
      # Simple wedding optimization logic
      price <= 500 && # Reasonable price for wedding travel
      departure_date.hour >= 8 && departure_date.hour <= 18 # Reasonable departure time
    end
  end
end 