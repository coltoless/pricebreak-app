class AutoBuyJob < ApplicationJob
  queue_as :default

  def perform(price_alert, current_price)
    return if price_alert.auto_buy_setting.max_attempts_reached?

    price_alert.auto_buy_setting.increment_attempts!

    begin
      # Attempt to purchase the ticket
      result = purchase_ticket(price_alert, current_price)

      if result.success?
        notify_success(price_alert, current_price)
        price_alert.update(status: 'triggered')
      else
        notify_failure(price_alert, current_price, result.error)
      end
    rescue StandardError => e
      notify_failure(price_alert, current_price, e.message)
    end
  end

  private

  def purchase_ticket(price_alert, current_price)
    # This is a placeholder for the actual ticket purchase logic
    # You would integrate with your ticket vendor's API here
    TicketPurchaseService.new(
      price_alert: price_alert,
      current_price: current_price
    ).execute
  end

  def notify_success(price_alert, current_price)
    PriceAlertMailer.auto_buy_success_email(price_alert, current_price).deliver_later
    
    ActionCable.server.broadcast(
      "notifications_#{price_alert.user.id}",
      {
        type: 'auto_buy_success',
        message: "Successfully purchased ticket at $#{current_price}!",
        alert_id: price_alert.id,
        current_price: current_price
      }
    )
  end

  def notify_failure(price_alert, current_price, error_message)
    PriceAlertMailer.auto_buy_failure_email(price_alert, current_price, error_message).deliver_later
    
    ActionCable.server.broadcast(
      "notifications_#{price_alert.user.id}",
      {
        type: 'auto_buy_failure',
        message: "Failed to purchase ticket: #{error_message}",
        alert_id: price_alert.id,
        current_price: current_price
      }
    )
  end
end 