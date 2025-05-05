class TicketApiJob < ApplicationJob
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
    when 'ticketmaster'
      TicketApis::TicketmasterService.new
    when 'seatgeek'
      TicketApis::SeatgeekService.new
    when 'stubhub'
      TicketApis::StubhubService.new
    when 'vividseats'
      TicketApis::VividseatsService.new
    when 'skyscanner'
      TicketApis::SkyscannerService.new
    end
  end

  def broadcast_result(service_name, method_name, result)
    ActionCable.server.broadcast(
      "ticket_api_channel",
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
      "ticket_api_channel",
      {
        service: service_name,
        method: method_name,
        status: 'error',
        error: error
      }
    )
  end
end 