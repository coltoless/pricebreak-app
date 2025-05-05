class PriceAlertMailer < ApplicationMailer
  def price_alert_email(price_alert, current_price)
    @price_alert = price_alert
    @current_price = current_price
    @user = price_alert.user

    mail(
      to: @user.email,
      subject: "Price Alert: Ticket price dropped to $#{current_price}"
    )
  end

  def auto_buy_success_email(price_alert, current_price)
    @price_alert = price_alert
    @current_price = current_price
    @user = price_alert.user

    mail(
      to: @user.email,
      subject: "Success! Ticket purchased at $#{current_price}"
    )
  end

  def auto_buy_failure_email(price_alert, current_price, error_message)
    @price_alert = price_alert
    @current_price = current_price
    @error_message = error_message
    @user = price_alert.user

    mail(
      to: @user.email,
      subject: "Failed to purchase ticket at $#{current_price}"
    )
  end
end 