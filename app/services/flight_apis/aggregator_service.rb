module FlightApis
  class AggregatorService
    def initialize
      @services = {
        skyscanner: SkyscannerService.new,
        amadeus: AmadeusService.new,
        google_flights: GoogleFlightsService.new
        # Add more flight APIs as they're implemented:
        # kiwi: KiwiService.new,
        # expedia: ExpediaService.new,
        # kayak: KayakService.new
      }
      
      @data_normalizer = FlightApis::DataNormalizerService.new
      @duplicate_detector = DuplicateDetectorService.new
      @rate_limiters = {}
      
      # Initialize rate limiters for each service
      @services.keys.each do |provider|
        @rate_limiters[provider] = FlightApis::RateLimiterService.new(provider)
      end
    end

    def search_all(params = {})
      results = []
      errors = []
      
      # Determine search strategy based on configuration
      strategy = FLIGHT_API_GLOBAL_CONFIG[:fallback_strategy]
      
      case strategy
      when :cascade
        results, errors = search_with_cascade_strategy(params)
      when :parallel
        results, errors = search_with_parallel_strategy(params)
      when :priority
        results, errors = search_with_priority_strategy(params)
      else
        results, errors = search_with_cascade_strategy(params)
      end
      
      # Normalize and deduplicate results
      normalized_results = normalize_and_deduplicate_results(results)
      
      # Sort results
      sorted_results = sort_flight_results(normalized_results, params[:sort_by])
      
      {
        success: true,
        results: sorted_results,
        total_count: sorted_results.length,
        providers_queried: @services.keys,
        errors: errors,
        search_strategy: strategy
      }
    rescue => e
      Rails.logger.error("Aggregator search error: #{e.message}")
      { success: false, results: [], errors: [e.message] }
    end

    def search_wedding_packages(wedding_date, destination, guest_count = 1)
      results = []
      errors = []
      
      @services.each do |service_name, service|
        begin
          if @rate_limiters[service_name].can_make_request?
            service_results = service.search_wedding_packages(wedding_date, destination, guest_count)
            results.concat(service_results)
          else
            errors << "#{service_name} rate limit exceeded"
          end
        rescue => e
          errors << "Error fetching from #{service_name}: #{e.message}"
          Rails.logger.error("Error fetching wedding packages from #{service_name}: #{e.message}")
        end
      end

      # Normalize and deduplicate results
      normalized_results = normalize_and_deduplicate_results(results)
      
      sort_flight_results(normalized_results, 'wedding_optimized')
    end

    def get_flight_details(flight_id, source = 'skyscanner')
      service = @services[source.to_sym]
      return nil unless service

      begin
        if @rate_limiters[source.to_sym].can_make_request?
          service.get_flight_details(flight_id)
        else
          Rails.logger.warn("#{source} rate limit exceeded for flight details")
          nil
        end
      rescue => e
        Rails.logger.error("Error fetching flight details from #{service.class.name}: #{e.message}")
        nil
      end
    end

    def get_price_history(route, date_range)
      results = []
      errors = []
      
      @services.each do |service_name, service|
        begin
          if @rate_limiters[service_name].can_make_request?
            if service.respond_to?(:get_price_history)
              service_results = service.get_price_history(route, date_range)
              results.concat(service_results)
            end
          else
            errors << "#{service_name} rate limit exceeded"
          end
        rescue => e
          errors << "Error fetching price history from #{service_name}: #{e.message}"
          Rails.logger.error("Error fetching price history from #{service_name}: #{e.message}")
        end
      end

      # Normalize and deduplicate results
      normalized_results = normalize_and_deduplicate_results(results)
      
      # Group by date and calculate average prices
      group_and_average_prices(normalized_results, date_range)
    end

    def get_airport_suggestions(query)
      results = []
      errors = []
      
      @services.each do |service_name, service|
        begin
          if @rate_limiters[service_name].can_make_request?
            if service.respond_to?(:get_airport_suggestions)
              service_results = service.get_airport_suggestions(query)
              results.concat(service_results)
            end
          else
            errors << "#{service_name} rate limit exceeded"
          end
        rescue => e
          errors << "Error fetching airport suggestions from #{service_name}: #{e.message}"
          Rails.logger.error("Error fetching airport suggestions from #{service_name}: #{e.message}")
        end
      end

      # Deduplicate airport suggestions by code
      deduplicated_results = results.uniq { |airport| airport[:code] }
      
      # Sort by relevance (exact matches first)
      sort_airport_suggestions(deduplicated_results, query)
    end

    def get_provider_health_status
      health_status = {}
      
      @rate_limiters.each do |provider, limiter|
        health_status[provider] = limiter.health_check
      end
      
      health_status
    end

    def get_price_insights(route, date_range)
      insights = {}
      
      @services.each do |service_name, service|
        begin
          if service.respond_to?(:get_price_insights) && @rate_limiters[service_name].can_make_request?
            service_insights = service.get_price_insights(route, date_range)
            insights[service_name] = service_insights if service_insights
          end
        rescue => e
          Rails.logger.error("Error getting price insights from #{service_name}: #{e.message}")
        end
      end
      
      # Aggregate insights across providers
      aggregate_price_insights(insights)
    end

    private

    def search_with_cascade_strategy(params)
      results = []
      errors = []
      
      # Try providers in order until we get enough results
      @services.each do |service_name, service|
        begin
          if @rate_limiters[service_name].can_make_request?
            service_results = service.search_flights(params)
            results.concat(service_results)
            
            # If we have enough results, stop searching
            if results.length >= (params[:max_results] || 50)
              break
            end
          else
            errors << "#{service_name} rate limit exceeded"
          end
        rescue => e
          errors << "Error fetching from #{service_name}: #{e.message}"
          Rails.logger.error("Error fetching from #{service_name}: #{e.message}")
        end
      end
      
      [results, errors]
    end

    def search_with_parallel_strategy(params)
      results = []
      errors = []
      
      # Search all providers simultaneously
      threads = @services.map do |service_name, service|
        Thread.new do
          begin
            if @rate_limiters[service_name].can_make_request?
              service.search_flights(params)
            else
              errors << "#{service_name} rate limit exceeded"
              []
            end
          rescue => e
            errors << "Error fetching from #{service_name}: #{e.message}"
            []
          end
        end
      end
      
      # Collect results from all threads
      threads.each do |thread|
        thread_results = thread.value
        results.concat(thread_results) if thread_results
      end
      
      [results, errors]
    end

    def search_with_priority_strategy(params)
      results = []
      errors = []
      
      # Sort providers by priority and search in order
      sorted_services = @services.sort_by { |name, _| FLIGHT_APIS_CONFIG[name][:fallback_priority] }
      
      sorted_services.each do |service_name, service|
        begin
          if @rate_limiters[service_name].can_make_request?
            service_results = service.search_flights(params)
            results.concat(service_results)
          else
            errors << "#{service_name} rate limit exceeded"
          end
        rescue => e
          errors << "Error fetching from #{service_name}: #{e.message}"
          Rails.logger.error("Error fetching from #{service_name}: #{e.message}")
        end
      end
      
      [results, errors]
    end

    def normalize_and_deduplicate_results(results)
      return [] if results.empty?
      
      # Normalize data from all providers
      normalized_data = []
      
      results.each do |result|
        provider = result[:source] || result[:provider] || 'unknown'
        normalized = @data_normalizer.normalize_single_flight(result, provider)
        normalized_data << normalized if normalized
      end
      
      # Detect and merge duplicates
      if FLIGHT_API_GLOBAL_CONFIG[:duplicate_detection_enabled]
        deduplicated_data = deduplicate_results(normalized_data)
      else
        deduplicated_data = normalized_data
      end
      
      deduplicated_data
    end

    def deduplicate_results(normalized_data)
      # Group by route and date
      grouped_data = normalized_data.group_by { |flight| "#{flight[:origin][:code]}-#{flight[:destination][:code]}-#{flight[:departure_date]}" }
      
      deduplicated = []
      
      grouped_data.each do |route_date, flights|
        if flights.length == 1
          deduplicated << flights.first
        else
          # Find the best flight from the group
          best_flight = select_best_flight(flights)
          deduplicated << best_flight
        end
      end
      
      deduplicated
    end

    def select_best_flight(flights)
      # Score flights based on multiple criteria
      scored_flights = flights.map do |flight|
        score = calculate_flight_score(flight)
        { flight: flight, score: score }
      end
      
      # Return the flight with the highest score
      scored_flights.max_by { |scored| scored[:score] }[:flight]
    end

    def calculate_flight_score(flight)
      score = 0
      
      # Price score (lower is better)
      if flight[:price]
        score += (1000 - flight[:price]) / 10
      end
      
      # Direct flight bonus
      if flight[:outbound] && flight[:outbound][:direct]
        score += 100
      end
      
      # Data quality score
      if flight[:data_quality_score]
        score += flight[:data_quality_score] * 50
      end
      
      # Provider reliability score
      provider_score = get_provider_reliability_score(flight[:source])
      score += provider_score * 25
      
      score
    end

    def get_provider_reliability_score(provider)
      case provider.to_s.downcase
      when 'skyscanner'
        0.9
      when 'amadeus'
        0.95
      when 'google_flights'
        0.85
      else
        0.7
      end
    end

    def group_and_average_prices(results, date_range)
      # Group results by date and calculate average prices
      grouped_by_date = results.group_by { |flight| flight[:departure_date] }
      
      price_history = date_range.map do |date|
        flights_for_date = grouped_by_date[date] || []
        
        if flights_for_date.any?
          prices = flights_for_date.map { |f| f[:price] }.compact
          {
            date: date,
            average_price: prices.sum / prices.length,
            min_price: prices.min,
            max_price: prices.max,
            price_count: prices.length,
            providers: flights_for_date.map { |f| f[:source] }.uniq
          }
        else
          {
            date: date,
            average_price: nil,
            min_price: nil,
            max_price: nil,
            price_count: 0,
            providers: []
          }
        end
      end
      
      price_history
    end

    def sort_airport_suggestions(airports, query)
      airports.sort_by do |airport|
        code = airport[:code].to_s.upcase
        name = airport[:name].to_s.upcase
        city = airport[:city].to_s.upcase
        query_up = query.to_s.upcase
        
        # Exact code match gets highest priority
        if code == query_up
          0
        # Code starts with query
        elsif code.start_with?(query_up)
          1
        # Name contains query
        elsif name.include?(query_up)
          2
        # City contains query
        elsif city.include?(query_up)
          3
        else
          4
        end
      end
    end

    def aggregate_price_insights(insights)
      return nil if insights.empty?
      
      all_prices = []
      all_trends = []
      
      insights.each do |provider, provider_insights|
        if provider_insights[:price_range]
          all_prices << provider_insights[:price_range]
        end
        
        if provider_insights[:price_trend]
          all_trends << provider_insights[:price_trend]
        end
      end
      
      return nil if all_prices.empty?
      
      # Aggregate price ranges
      aggregated_range = {
        min: all_prices.map { |p| p[:min] }.min,
        max: all_prices.map { |p| p[:max] }.max,
        average: all_prices.map { |p| p[:average] }.sum / all_prices.length
      }
      
      # Determine overall trend
      trend_counts = all_trends.group_by(&:itself).transform_values(&:count)
      overall_trend = trend_counts.max_by { |_, count| count }&.first || 'stable'
      
      {
        aggregated_price_range: aggregated_range,
        overall_trend: overall_trend,
        provider_insights: insights,
        confidence: calculate_insights_confidence(insights)
      }
    end

    def calculate_insights_confidence(insights)
      # Calculate confidence based on number of providers and consistency
      provider_count = insights.length
      return 0.5 if provider_count == 0
      
      # Base confidence on provider count
      base_confidence = [provider_count / 3.0, 1.0].min
      
      # Adjust based on consistency of trends
      trends = insights.values.map { |i| i[:price_trend] }.compact
      if trends.length > 1
        trend_consistency = trends.uniq.length.to_f / trends.length
        consistency_bonus = (1.0 - trend_consistency) * 0.2
        base_confidence += consistency_bonus
      end
      
      [base_confidence, 1.0].min
    end

    def sort_flight_results(results, sort_by = 'price')
      case sort_by
      when 'price'
        results.sort_by { |flight| flight[:price] || Float::INFINITY }
      when 'duration'
        results.sort_by { |flight| flight[:duration] || Float::INFINITY }
      when 'departure_time'
        results.sort_by { |flight| flight[:departure_date] || Date.today }
      when 'wedding_optimized'
        results.sort_by { |flight| [flight[:wedding_optimized] ? 0 : 1, flight[:price] || Float::INFINITY] }
      when 'best_value'
        results.sort_by { |flight| -calculate_value_score(flight) }
      when 'data_quality'
        results.sort_by { |flight| -(flight[:data_quality_score] || 0) }
      else
        results.sort_by { |flight| flight[:price] || Float::INFINITY }
      end
    end

    def calculate_value_score(flight)
      # Calculate a value score based on price, convenience, and data quality
      price_score = flight[:price] ? (1000 - flight[:price]) : 0
      convenience_score = flight[:outbound]&.dig(:direct) ? 100 : 50
      quality_score = (flight[:data_quality_score] || 0.5) * 100
      
      price_score + convenience_score + quality_score
    end
  end
end 