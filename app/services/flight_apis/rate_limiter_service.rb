module FlightApis
  class RateLimiterService
    def initialize(provider_name)
      @provider_name = provider_name.to_sym
      @config = FLIGHT_APIS_CONFIG[@provider_name]
      raise "Unknown provider: #{provider_name}" unless @config
      
      @redis = Redis.new
    end

    def can_make_request?
      return false if rate_limit_exceeded?
      return false if burst_limit_exceeded?
      true
    end

    def record_request
      return false unless can_make_request?
      
      # Record request in Redis with expiration
      current_time = Time.current.to_i
      
      # Increment per-minute counter
      @redis.multi do |multi|
        multi.incr("rate_limit:#{@provider_name}:per_minute:#{current_time / 60}")
        multi.expire("rate_limit:#{@provider_name}:per_minute:#{current_time / 60}", 60)
        
        # Increment per-hour counter
        multi.incr("rate_limit:#{@provider_name}:per_hour:#{current_time / 3600}")
        multi.expire("rate_limit:#{@provider_name}:per_hour:#{current_time / 3600}", 3600)
        
        # Increment burst counter
        multi.incr("rate_limit:#{@provider_name}:burst:#{current_time / 10}")
        multi.expire("rate_limit:#{@provider_name}:burst:#{current_time / 10}", 10)
      end
      
      true
    end

    def wait_time_until_available
      return 0 if can_make_request?
      
      # Calculate wait time based on which limit is exceeded
      if burst_limit_exceeded?
        return 10.seconds
      elsif requests_per_minute >= @config[:rate_limit][:requests_per_minute]
        return 60.seconds
      elsif requests_per_hour >= @config[:rate_limit][:requests_per_hour]
        return 3600.seconds
      end
      
      0
    end

    def get_retry_delay(attempt_number)
      base_delay = @config[:retry_delay_seconds] || 5
      exponential_backoff = base_delay * (2 ** attempt_number)
      jitter = rand(0.5..1.5) # Add randomness to prevent thundering herd
      
      [exponential_backoff * jitter, 300].min # Cap at 5 minutes
    end

    def reset_limits
      current_time = Time.current.to_i
      
      @redis.del("rate_limit:#{@provider_name}:per_minute:#{current_time / 60}")
      @redis.del("rate_limit:#{@provider_name}:per_hour:#{current_time / 3600}")
      @redis.del("rate_limit:#{@provider_name}:burst:#{current_time / 10}")
    end

    def current_usage
      {
        provider: @provider_name,
        requests_per_minute: requests_per_minute,
        requests_per_hour: requests_per_hour,
        burst_requests: burst_requests,
        limits: @config[:rate_limit],
        can_make_request: can_make_request?,
        wait_time: wait_time_until_available
      }
    end

    def health_check
      {
        provider: @provider_name,
        status: can_make_request? ? 'healthy' : 'rate_limited',
        usage_percentage: {
          per_minute: (requests_per_minute.to_f / @config[:rate_limit][:requests_per_minute] * 100).round(2),
          per_hour: (requests_per_hour.to_f / @config[:rate_limit][:requests_per_hour] * 100).round(2),
          burst: (burst_requests.to_f / @config[:rate_limit][:burst_limit] * 100).round(2)
        },
        next_reset: {
          per_minute: Time.at((Time.current.to_i / 60 + 1) * 60),
          per_hour: Time.at((Time.current.to_i / 3600 + 1) * 3600),
          burst: Time.at((Time.current.to_i / 10 + 1) * 10)
        }
      }
    end

    private

    def rate_limit_exceeded?
      requests_per_minute >= @config[:rate_limit][:requests_per_minute] ||
      requests_per_hour >= @config[:rate_limit][:requests_per_hour]
    end

    def burst_limit_exceeded?
      burst_requests >= @config[:rate_limit][:burst_limit]
    end

    def requests_per_minute
      current_time = Time.current.to_i
      key = "rate_limit:#{@provider_name}:per_minute:#{current_time / 60}"
      @redis.get(key).to_i
    end

    def requests_per_hour
      current_time = Time.current.to_i
      key = "rate_limit:#{@provider_name}:per_hour:#{current_time / 3600}"
      @redis.get(key).to_i
    end

    def burst_requests
      current_time = Time.current.to_i
      key = "rate_limit:#{@provider_name}:burst:#{current_time / 10}"
      @redis.get(key).to_i
    end
  end
end
