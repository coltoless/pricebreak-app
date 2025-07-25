module FlightApis
  class CacheService
    def self.fetch(key, expires_in: 1.hour, &block)
      Rails.cache.fetch("flight_apis/#{key}", expires_in: expires_in) do
        block.call
      end
    end

    def self.clear_flight_cache
      Rails.cache.delete_matched("flight_apis/*")
    end

    def self.clear_price_cache
      Rails.cache.delete_matched("flight_apis/*/price*")
    end
  end
end 