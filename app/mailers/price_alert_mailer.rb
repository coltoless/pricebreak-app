class PriceAlertMailer < ApplicationMailer
  # Main price break alert with smart content
  def price_break_alert(alert, email_content)
    @alert = alert
    @user = alert.flight_filter&.user || alert.user
    @email_content = email_content
    @smart_content = email_content[:body]
    @urgency = email_content[:body][:urgency]
    @template = email_content[:template] || 'standard_price_alert'

    mail(
      to: @user&.email || alert.email,
      subject: email_content[:subject],
      template_name: @template
    )
  end

  # Urgent price alert template
  def urgent_price_alert(alert, email_content)
    @alert = alert
    @user = alert.flight_filter&.user || alert.user
    @email_content = email_content
    @smart_content = email_content[:body]
    @urgency = :urgent

    mail(
      to: @user&.email || alert.email,
      subject: email_content[:subject],
      template_name: 'urgent_price_alert'
    )
  end

  # Significant price alert template
  def significant_price_alert(alert, email_content)
    @alert = alert
    @user = alert.flight_filter&.user || alert.user
    @email_content = email_content
    @smart_content = email_content[:body]
    @urgency = :significant

    mail(
      to: @user&.email || alert.email,
      subject: email_content[:subject],
      template_name: 'significant_price_alert'
    )
  end

  # Minor price alert template
  def minor_price_alert(alert, email_content)
    @alert = alert
    @user = alert.flight_filter&.user || alert.user
    @email_content = email_content
    @smart_content = email_content[:body]
    @urgency = :minor

    mail(
      to: @user&.email || alert.email,
      subject: email_content[:subject],
      template_name: 'minor_price_alert'
    )
  end

  # Price digest for multiple minor alerts
  def price_digest(user, alerts)
    @user = user
    @alerts = alerts
    @total_savings = alerts.sum(&:price_drop_amount)
    @alert_count = alerts.count

    mail(
      to: @user.email,
      subject: "PriceBreak Digest: #{@alert_count} price updates - Save $#{@total_savings}"
    )
  end

  # Legacy price alert email
  def price_alert_email(price_alert, current_price)
    @price_alert = price_alert
    @current_price = current_price
    @user = price_alert.user

    mail(
      to: @user.email,
      subject: "Price Alert: Ticket price dropped to $#{current_price}"
    )
  end

  # Auto-buy success notification
  def auto_buy_success_email(price_alert, current_price)
    @price_alert = price_alert
    @current_price = current_price
    @user = price_alert.user

    mail(
      to: @user.email,
      subject: "Success! Ticket purchased at $#{current_price}"
    )
  end

  # Auto-buy failure notification
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

  # Alert quality improvement notification
  def alert_quality_improvement(alert, improvements)
    @alert = alert
    @user = alert.flight_filter&.user || alert.user
    @improvements = improvements

    mail(
      to: @user&.email || alert.email,
      subject: "Your PriceBreak alert has been improved"
    )
  end

  # Alert expiration warning
  def alert_expiration_warning(alert, days_remaining)
    @alert = alert
    @user = alert.flight_filter&.user || alert.user
    @days_remaining = days_remaining

    mail(
      to: @user&.email || alert.email,
      subject: "Your PriceBreak alert expires in #{days_remaining} days"
    )
  end

  # Weekly summary email
  def weekly_summary(user, summary_data)
    @user = user
    @summary_data = summary_data
    @total_savings = summary_data[:total_savings]
    @alerts_triggered = summary_data[:alerts_triggered]
    @top_deals = summary_data[:top_deals]

    mail(
      to: @user.email,
      subject: "Your PriceBreak Weekly Summary - $#{@total_savings} in potential savings"
    )
  end

  # Unsubscribe confirmation
  def unsubscribe_confirmation(user, alert_id = nil)
    @user = user
    @alert_id = alert_id

    mail(
      to: @user.email,
      subject: "You've been unsubscribed from PriceBreak alerts"
    )
  end

  private

  # Helper method to determine if user has mobile app
  def user_has_mobile_app?
    @user&.has_mobile_app? || false
  end

  # Helper method to get user's preferred name
  def user_display_name
    @user&.first_name || @user&.name || 'there'
  end

  # Helper method to format currency
  def format_currency(amount)
    "$#{amount.to_i}"
  end

  # Helper method to format percentage
  def format_percentage(percentage)
    "#{percentage.round(1)}%"
  end

  # Helper method to get urgency emoji
  def urgency_emoji(urgency)
    case urgency
    when :urgent then "🚨"
    when :significant then "🎉"
    when :minor then "💰"
    else "📱"
    end
  end

  # Helper method to get urgency color
  def urgency_color(urgency)
    case urgency
    when :urgent then "#dc2626" # red
    when :significant then "#059669" # green
    when :minor then "#2563eb" # blue
    else "#6b7280" # gray
    end
  end
end 