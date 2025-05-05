module TicketApis
  class StubhubService < BaseApiService
    def search_events(params = {})
      endpoint = '/catalog/events/v3'
      response = make_request(endpoint, params)
      transform_events(response['events'])
    end

    def get_event_details(event_id)
      endpoint = "/catalog/events/v3/#{event_id}"
      response = make_request(endpoint)
      transform_event(response['event'])
    end

    private

    def api_key_name
      :stubhub
    end

    def base_url
      'https://api.stubhub.com'
    end

    def api_key_params
      {
        'Authorization' => "Bearer #{@api_key}",
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
        url: event['webURI'],
        start_date: event['eventDateLocal'],
        end_date: event['eventDateUTC'],
        status: event['status'],
        venue: {
          name: event['venue']['name'],
          city: event['venue']['city'],
          state: event['venue']['state'],
          country: event['venue']['country']
        },
        price_ranges: [{
          min: event['ticketInfo']['minPrice'],
          max: event['ticketInfo']['maxPrice'],
          currency: event['ticketInfo']['currency']
        }],
        images: event['images'].map { |img| img['url'] },
        classifications: event['categories'].map { |cat| cat['name'] },
        source: 'stubhub'
      }
    end
  end
end 