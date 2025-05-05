module TicketApis
  class SkyscannerService < BaseApiService
    def search_flights(params = {})
      endpoint = '/flights/browse'
      response = make_request(endpoint, params)
      transform_flights(response['Quotes'])
    end

    def get_flight_details(quote_id)
      endpoint = "/flights/quotes/#{quote_id}"
      response = make_request(endpoint)
      transform_flight(response)
    end

    private

    def api_key_name
      :skyscanner
    end

    def base_url
      'https://skyscanner-api.p.rapidapi.com'
    end

    def api_key_params
      {
        'X-RapidAPI-Key' => @api_key,
        'X-RapidAPI-Host' => 'skyscanner-api.p.rapidapi.com'
      }
    end

    def make_request(endpoint, params = {})
      uri = URI("#{@base_url}#{endpoint}")
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Get.new(uri)
      api_key_params.each { |key, value| request[key] = value }
      request['Accept'] = 'application/json'
      
      response = http.request(request)
      handle_response(response)
    end

    def transform_flights(quotes)
      quotes.map { |quote| transform_flight(quote) }
    end

    def transform_flight(quote)
      {
        id: quote['QuoteId'],
        price: quote['MinPrice'],
        currency: quote['Currency'],
        direct: quote['Direct'],
        departure_date: quote['OutboundLeg']['DepartureDate'],
        return_date: quote['InboundLeg']['DepartureDate'],
        origin: {
          code: quote['OutboundLeg']['OriginId'],
          name: quote['OutboundLeg']['OriginName']
        },
        destination: {
          code: quote['OutboundLeg']['DestinationId'],
          name: quote['OutboundLeg']['DestinationName']
        },
        airline: quote['OutboundLeg']['CarrierIds'][0],
        source: 'skyscanner'
      }
    end
  end
end 