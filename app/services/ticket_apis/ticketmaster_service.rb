module TicketApis
  class TicketmasterService < BaseApiService
    def search_events(params = {})
      endpoint = '/discovery/v2/events.json'
      response = make_request(endpoint, params)
      transform_events(response['_embedded']['events'])
    end

    def get_event_details(event_id)
      endpoint = "/discovery/v2/events/#{event_id}.json"
      response = make_request(endpoint)
      transform_event(response)
    end

    private

    def api_key_name
      :ticketmaster
    end

    def base_url
      'https://app.ticketmaster.com'
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
        start_date: event['dates']['start']['dateTime'],
        end_date: event['dates']['end']['dateTime'],
        status: event['dates']['status']['code'],
        venue: {
          name: event['_embedded']['venues'][0]['name'],
          city: event['_embedded']['venues'][0]['city']['name'],
          state: event['_embedded']['venues'][0]['state']['name'],
          country: event['_embedded']['venues'][0]['country']['name']
        },
        price_ranges: event['priceRanges'],
        images: event['images'],
        classifications: event['classifications'],
        source: 'ticketmaster'
      }
    end
  end
end 