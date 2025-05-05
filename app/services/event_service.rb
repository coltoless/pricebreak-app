require 'net/http'
require 'json'

class EventService
  TICKETMASTER_API_KEY = ENV['TICKETMASTER_API_KEY']
  TICKETMASTER_BASE_URL = 'https://app.ticketmaster.com/discovery/v2'

  def self.fetch_events(params = {})
    uri = URI("#{TICKETMASTER_BASE_URL}/events.json")
    uri.query = URI.encode_www_form(build_query_params(params))
    
    response = Net::HTTP.get_response(uri)
    return [] unless response.is_a?(Net::HTTPSuccess)
    
    data = JSON.parse(response.body)
    transform_events(data['_embedded']['events'])
  rescue StandardError => e
    Rails.logger.error("Error fetching events: #{e.message}")
    []
  end

  private

  def self.build_query_params(params)
    {
      apikey: TICKETMASTER_API_KEY,
      size: 20,
      sort: 'date,asc',
      classificationName: params[:category],
      keyword: params[:q],
      startDateTime: params[:start_date],
      endDateTime: params[:end_date],
      priceMin: params[:price_min],
      priceMax: params[:price_max]
    }.compact
  end

  def self.transform_events(events)
    return [] unless events

    events.map do |event|
      {
        name: event['name'],
        description: event['description'],
        venue: event['_embedded']['venues'].first['name'],
        category: event['classifications'].first['segment']['name'],
        subcategory: event['classifications'].first['genre']['name'],
        price: event['priceRanges']&.first&.dig('min') || 0,
        date: event['dates']['start']['dateTime'],
        image_url: event['images'].find { |img| img['ratio'] == '16_9' }&.dig('url'),
        ticket_url: event['url']
      }
    end
  end
end 