module TicketApis
  class AggregatorService
    def initialize
      @services = {
        ticketmaster: TicketmasterService.new,
        seatgeek: SeatgeekService.new,
        stubhub: StubhubService.new,
        vividseats: VividseatsService.new,
        skyscanner: SkyscannerService.new
      }
    end

    def search_all(params = {})
      results = {
        events: search_events(params),
        flights: search_flights(params)
      }
      
      sort_results(results, params[:sort_by])
    end

    def search_events(params = {})
      event_services = [
        @services[:ticketmaster],
        @services[:seatgeek],
        @services[:stubhub],
        @services[:vividseats]
      ]
      results = []

      event_services.each do |service|
        begin
          # Enqueue background job for each service
          TicketApiJob.perform_later(
            service.class.name.demodulize.underscore,
            'search_events',
            params
          )
          
          # Also get immediate results from cache
          results.concat(service.search_events(params))
        rescue => e
          Rails.logger.error("Error fetching from #{service.class.name}: #{e.message}")
        end
      end

      results
    end

    def search_flights(params = {})
      begin
        # Enqueue background job for flight search
        TicketApiJob.perform_later(
          'skyscanner',
          'search_flights',
          params
        )
        
        # Also get immediate results from cache
        @services[:skyscanner].search_flights(params)
      rescue => e
        Rails.logger.error("Error fetching flights: #{e.message}")
        []
      end
    end

    private

    def sort_results(results, sort_by = nil)
      return results unless sort_by

      case sort_by
      when 'price_asc'
        results[:events].sort_by! { |e| e[:price_ranges].first[:min] }
        results[:flights].sort_by! { |f| f[:price] }
      when 'price_desc'
        results[:events].sort_by! { |e| -e[:price_ranges].first[:min] }
        results[:flights].sort_by! { |f| -f[:price] }
      when 'date_asc'
        results[:events].sort_by! { |e| e[:start_date] }
        results[:flights].sort_by! { |f| f[:departure_date] }
      when 'date_desc'
        results[:events].sort_by! { |e| -e[:start_date] }
        results[:flights].sort_by! { |f| -f[:departure_date] }
      end

      results
    end
  end
end 