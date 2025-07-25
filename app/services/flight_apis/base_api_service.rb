module FlightApis
  class BaseApiService
    require 'net/http'
    require 'json'

    def initialize
      @api_key = Rails.application.credentials.dig(:api_keys, api_key_name)
      @base_url = base_url
    end

    def search_flights(params = {})
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    def get_flight_details(flight_id)
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    def search_wedding_packages(wedding_date, destination, guest_count = 1)
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    def get_price_history(route, date_range)
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    def get_airport_suggestions(query)
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    protected

    def make_request(endpoint, params = {})
      cache_key = generate_cache_key(endpoint, params)
      
      FlightApis::CacheService.fetch(cache_key) do
        uri = URI("#{@base_url}#{endpoint}")
        uri.query = URI.encode_www_form(params.merge(api_key_params))
        
        response = Net::HTTP.get_response(uri)
        handle_response(response)
      end
    end

    def handle_response(response)
      case response
      when Net::HTTPSuccess
        JSON.parse(response.body)
      when Net::HTTPUnauthorized
        raise "API key is invalid or expired"
      when Net::HTTPTooManyRequests
        raise "Rate limit exceeded"
      else
        raise "API request failed: #{response.message}"
      end
    end

    def api_key_params
      { api_key: @api_key }
    end

    def api_key_name
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    def base_url
      raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
    end

    private

    def generate_cache_key(endpoint, params)
      "#{self.class.name.downcase}/#{endpoint}/#{params.sort.to_h}"
    end

    def format_date_for_api(date)
      date.strftime('%Y-%m-%d')
    end

    def parse_airport_code(code)
      # Handle various airport code formats
      code.to_s.upcase.strip
    end

    def validate_flight_params(params)
      required_fields = [:origin, :destination, :departure_date]
      missing_fields = required_fields.select { |field| params[field].blank? }
      
      if missing_fields.any?
        raise ArgumentError, "Missing required fields: #{missing_fields.join(', ')}"
      end
    end
  end
end 