module TicketApis
  class CacheService
    CACHE_EXPIRY = 15.minutes

    def self.fetch(key, &block)
      Rails.cache.fetch(cache_key(key), expires_in: CACHE_EXPIRY) do
        block.call
      end
    end

    def self.cache_key(key)
      "ticket_api/#{key}"
    end

    def self.invalidate(key)
      Rails.cache.delete(cache_key(key))
    end
  end
end 