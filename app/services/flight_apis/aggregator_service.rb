module FlightApis
  class AggregatorService
    def initialize
      @services = {
        skyscanner: SkyscannerService.new
        # Add more flight APIs as they're implemented:
        # amadeus: AmadeusService.new,
        # google_flights: GoogleFlightsService.new,
        # kiwi: KiwiService.new,
        # expedia: ExpediaService.new,
        # kayak: KayakService.new
      }
    end

    def search_all(params = {})
      results = []
      
      @services.each do |service_name, service|
        begin
          # Enqueue background job for each service
          FlightApiJob.perform_later(
            service.class.name.demodulize.underscore,
            'search_flights',
            params
          )
          
          # Also get immediate results from cache
          service_results = service.search_flights(params)
          results.concat(service_results)
        rescue => e
          Rails.logger.error("Error fetching from #{service.class.name}: #{e.message}")
        end
      end

      sort_flight_results(results, params[:sort_by])
    end

    def search_wedding_packages(wedding_date, destination, guest_count = 1)
      results = []
      
      @services.each do |service_name, service|
        begin
          service_results = service.search_wedding_packages(wedding_date, destination, guest_count)
          results.concat(service_results)
        rescue => e
          Rails.logger.error("Error fetching wedding packages from #{service.class.name}: #{e.message}")
        end
      end

      sort_flight_results(results, 'wedding_optimized')
    end

    def get_flight_details(flight_id, source = 'skyscanner')
      service = @services[source.to_sym]
      return nil unless service

      begin
        service.get_flight_details(flight_id)
      rescue => e
        Rails.logger.error("Error fetching flight details from #{service.class.name}: #{e.message}")
        nil
      end
    end

    def get_price_history(route, date_range)
      results = []
      
      @services.each do |service_name, service|
        begin
          if service.respond_to?(:get_price_history)
            service_results = service.get_price_history(route, date_range)
            results.concat(service_results)
          end
        rescue => e
          Rails.logger.error("Error fetching price history from #{service.class.name}: #{e.message}")
        end
      end

      results
    end

    def get_airport_suggestions(query)
      results = []
      
      @services.each do |service_name, service|
        begin
          if service.respond_to?(:get_airport_suggestions)
            service_results = service.get_airport_suggestions(query)
            results.concat(service_results)
          end
        rescue => e
          Rails.logger.error("Error fetching airport suggestions from #{service.class.name}: #{e.message}")
        end
      end

      results.uniq { |airport| airport[:code] }
    end

    private

    def sort_flight_results(results, sort_by = 'price')
      case sort_by
      when 'price'
        results.sort_by { |flight| flight[:price] }
      when 'duration'
        results.sort_by { |flight| flight[:duration] || Float::INFINITY }
      when 'departure_time'
        results.sort_by { |flight| flight[:outbound][:departure_date] }
      when 'wedding_optimized'
        results.sort_by { |flight| [flight[:wedding_optimized] ? 0 : 1, flight[:price]] }
      when 'best_value'
        results.sort_by { |flight| calculate_value_score(flight) }
      else
        results.sort_by { |flight| flight[:price] }
      end
    end

    def calculate_value_score(flight)
      # Calculate a value score based on price, convenience, and wedding optimization
      price_score = 1000 - flight[:price] # Lower price = higher score
      convenience_score = flight[:outbound][:direct] ? 100 : 50
      wedding_score = flight[:wedding_optimized] ? 200 : 0
      
      price_score + convenience_score + wedding_score
    end
  end
end 