module TicketApis
  class SeatgeekService < BaseApiService
    def search_events(params = {})
      endpoint = '/events'
      response = make_request(endpoint, params)
      transform_events(response['events'])
    end

    def get_event_details(event_id)
      endpoint = "/events/#{event_id}"
      response = make_request(endpoint)
      transform_event(response['events'][0])
    end

    private

    def api_key_name
      :seatgeek
    end

    def base_url
      'https://api.seatgeek.com/2'
    end

    def api_key_params
      { client_id: @api_key }
    end

    def transform_events(events)
      events.map { |event| transform_event(event) }
    end

    def transform_event(event)
      {
        id: event['id'],
        name: event['title'],
        description: event['description'],
        url: event['url'],
        start_date: event['datetime_local'],
        end_date: event['datetime_utc'],
        status: event['status'],
        venue: {
          name: event['venue']['name'],
          city: event['venue']['city'],
          state: event['venue']['state'],
          country: event['venue']['country']
        },
        price_ranges: [{
          min: event['stats']['lowest_price'],
          max: event['stats']['highest_price'],
          currency: 'USD'
        }],
        images: event['performers'].map { |p| p['image'] },
        classifications: event['taxonomies'].map { |t| t['name'] },
        source: 'seatgeek'
      }
    end
  end
end 