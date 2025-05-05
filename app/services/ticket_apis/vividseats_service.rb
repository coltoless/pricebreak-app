module TicketApis
  class VividseatsService < BaseApiService
    def search_events(params = {})
      endpoint = '/api/v1/events'
      response = make_request(endpoint, params)
      transform_events(response['events'])
    end

    def get_event_details(event_id)
      endpoint = "/api/v1/events/#{event_id}"
      response = make_request(endpoint)
      transform_event(response['event'])
    end

    private

    def api_key_name
      :vividseats
    end

    def base_url
      'https://api.vividseats.com'
    end

    def api_key_params
      {
        'X-API-Key' => @api_key,
        'Accept' => 'application/json'
      }
    end

    def make_request(endpoint, params = {})
      uri = URI("#{@base_url}#{endpoint}")
      uri.query = URI.encode_www_form(params)
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Get.new(uri)
      api_key_params.each { |key, value| request[key] = value }
      
      response = http.request(request)
      handle_response(response)
    end

    def transform_events(events)
      events.map { |event| transform_event(event) }
    end

    def transform_event(event)
      {
        id: event['id'],
        name: event['name'],
        description: event['description'],
        url: event['url'],
        start_date: event['startDate'],
        end_date: event['endDate'],
        status: event['status'],
        venue: {
          name: event['venue']['name'],
          city: event['venue']['city'],
          state: event['venue']['state'],
          country: event['venue']['country']
        },
        price_ranges: [{
          min: event['minPrice'],
          max: event['maxPrice'],
          currency: event['currency']
        }],
        images: event['images'],
        classifications: event['categories'],
        source: 'vividseats'
      }
    end
  end
end 