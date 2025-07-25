class FlightApiJob < ApplicationJob
  queue_as :default

  def perform(service_name, method_name, params = {})
    service = get_service(service_name)
    return unless service

    begin
      result = service.public_send(method_name, params)
      broadcast_result(service_name, method_name, result)
    rescue => e
      Rails.logger.error("Error in #{service_name} #{method_name}: #{e.message}")
      broadcast_error(service_name, method_name, e.message)
    end
  end

  private

  def get_service(service_name)
    case service_name
    when 'skyscanner'
      FlightApis::SkyscannerService.new
    # Add more services as they're implemented:
    # when 'amadeus'
    #   FlightApis::AmadeusService.new
    # when 'google_flights'
    #   FlightApis::GoogleFlightsService.new
    # when 'kiwi'
    #   FlightApis::KiwiService.new
    # when 'expedia'
    #   FlightApis::ExpediaService.new
    # when 'kayak'
    #   FlightApis::KayakService.new
    end
  end

  def broadcast_result(service_name, method_name, result)
    ActionCable.server.broadcast(
      "flight_api_channel",
      {
        service: service_name,
        method: method_name,
        status: 'success',
        data: result
      }
    )
  end

  def broadcast_error(service_name, method_name, error)
    ActionCable.server.broadcast(
      "flight_api_channel",
      {
        service: service_name,
        method: method_name,
        status: 'error',
        error: error
      }
    )
  end
end 