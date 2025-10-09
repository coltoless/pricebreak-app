class AlertDeliveryJob < ApplicationJob
  queue_as :alerts

  # Retry on network errors
  retry_on Net::TimeoutError, wait: 30.seconds, attempts: 3
  retry_on Faraday::TimeoutError, wait: 30.seconds, attempts: 3
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  # Discard on specific errors
  discard_on ActiveRecord::RecordNotFound
  discard_on ArgumentError

  def perform(alert_id, delivery_method = :all, options = {})
    alert = FlightAlert.find(alert_id)
    
    Rails.logger.info "Delivering alert #{alert_id} via #{delivery_method}"
    
    # Use intelligent alert system
    intelligence = AlertIntelligenceService.new(alert, alert.current_price, options)
    
    # Check if alert should be sent
    unless intelligence.should_send_alert?
      Rails.logger.info "Alert #{alert_id} filtered out by intelligence system"
      return { success: false, error: "Alert filtered out by intelligence system" }
    end
    
    # Determine optimal delivery time
    optimal_time = intelligence.optimal_delivery_time
    
    if optimal_time && optimal_time > Time.current
      # Schedule for later delivery
      AlertDeliveryJob.set(wait_until: optimal_time).perform_later(alert_id, delivery_method, options)
      return { success: true, alert_id: alert_id, scheduled_for: optimal_time }
    end
    
    # Generate smart content
    smart_content = intelligence.generate_alert_content
    
    case delivery_method
    when :all
      deliver_with_intelligence(alert, smart_content, options)
    when :email
      deliver_email_alert(alert, smart_content)
    when :push
      deliver_push_alert(alert, smart_content)
    when :sms
      deliver_sms_alert(alert, smart_content)
    when :browser
      deliver_browser_alert(alert, smart_content)
    else
      Rails.logger.error "Unknown delivery method: #{delivery_method}"
      return { success: false, error: "Unknown delivery method: #{delivery_method}" }
    end
    
    { success: true, alert_id: alert_id, method: delivery_method, urgency: smart_content[:urgency] }
  rescue => e
    Rails.logger.error "Alert delivery failed for alert #{alert_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    # Record failed delivery
    alert&.add_notification_record(delivery_method.to_s, "Delivery failed: #{e.message}", false)
    
    { success: false, error: e.message }
  end

  private

  # Deliver alert with intelligence system
  def deliver_with_intelligence(alert, smart_content, options)
    # Use NotificationService for multi-channel delivery
    notification_service = NotificationService.new(alert, options)
    notification_service.content = smart_content
    notification_service.priority = smart_content[:urgency].to_s
    
    result = notification_service.send_notifications
    
    # Update alert quality score based on delivery success
    if result[:success]
      alert.update_quality_score
    end
    
    result
  end

  # Deliver alert via all enabled methods (legacy method)
  def deliver_all_methods(alert)
    results = { success: true, methods: [], errors: [] }
    
    # Get notification methods from alert settings
    notification_methods = alert.flight_filter&.notification_methods || { 'email' => true }
    
    # Deliver email if enabled
    if notification_methods['email']
      begin
        deliver_email_alert(alert)
        results[:methods] << 'email'
      rescue => e
        results[:errors] << "Email delivery failed: #{e.message}"
        results[:success] = false
      end
    end
    
    # Deliver push notification if enabled
    if notification_methods['push']
      begin
        deliver_push_alert(alert)
        results[:methods] << 'push'
      rescue => e
        results[:errors] << "Push delivery failed: #{e.message}"
        results[:success] = false
      end
    end
    
    # Deliver SMS if enabled
    if notification_methods['sms']
      begin
        deliver_sms_alert(alert)
        results[:methods] << 'sms'
      rescue => e
        results[:errors] << "SMS delivery failed: #{e.message}"
        results[:success] = false
      end
    end
    
    # Deliver browser notification if enabled
    if notification_methods['browser']
      begin
        deliver_browser_alert(alert)
        results[:methods] << 'browser'
      rescue => e
        results[:errors] << "Browser delivery failed: #{e.message}"
        results[:success] = false
      end
    end
    
    results
  end

  # Deliver email alert with smart content
  def deliver_email_alert(alert, smart_content = nil)
    # Generate smart content if not provided
    smart_content ||= AlertIntelligenceService.new(alert, alert.current_price).generate_alert_content
    
    # Generate email content using smart content
    email_content = generate_smart_email_content(alert, smart_content)
    
    # Send email (using Rails mailer)
    PriceAlertMailer.price_break_alert(alert, email_content).deliver_now
    
    # Record successful delivery
    alert.add_notification_record('email', email_content[:subject], true)
    
    Rails.logger.info "Email alert delivered for alert #{alert.id}"
  rescue => e
    Rails.logger.error "Email delivery failed for alert #{alert.id}: #{e.message}"
    alert.add_notification_record('email', "Delivery failed: #{e.message}", false)
    raise
  end

  # Deliver push notification with smart content
  def deliver_push_alert(alert, smart_content = nil)
    # Generate smart content if not provided
    smart_content ||= AlertIntelligenceService.new(alert, alert.current_price).generate_alert_content
    
    # Generate push notification content using smart content
    push_content = generate_smart_push_content(alert, smart_content)
    
    # Send push notification (using Firebase or similar)
    send_push_notification(alert, push_content)
    
    # Record successful delivery
    alert.add_notification_record('push', push_content[:title], true)
    
    Rails.logger.info "Push alert delivered for alert #{alert.id}"
  rescue => e
    Rails.logger.error "Push delivery failed for alert #{alert.id}: #{e.message}"
    alert.add_notification_record('push', "Delivery failed: #{e.message}", false)
    raise
  end

  # Deliver SMS alert with smart content
  def deliver_sms_alert(alert, smart_content = nil)
    # Generate smart content if not provided
    smart_content ||= AlertIntelligenceService.new(alert, alert.current_price).generate_alert_content
    
    # Generate SMS content using smart content
    sms_content = generate_smart_sms_content(alert, smart_content)
    
    # Send SMS (using Twilio or similar)
    send_sms_notification(alert, sms_content)
    
    # Record successful delivery
    alert.add_notification_record('sms', sms_content, true)
    
    Rails.logger.info "SMS alert delivered for alert #{alert.id}"
  rescue => e
    Rails.logger.error "SMS delivery failed for alert #{alert.id}: #{e.message}"
    alert.add_notification_record('sms', "Delivery failed: #{e.message}", false)
    raise
  end

  # Deliver browser notification with smart content
  def deliver_browser_alert(alert, smart_content = nil)
    # Generate smart content if not provided
    smart_content ||= AlertIntelligenceService.new(alert, alert.current_price).generate_alert_content
    
    # Generate browser notification content using smart content
    browser_content = generate_smart_browser_content(alert, smart_content)
    
    # Send browser notification via ActionCable
    ActionCable.server.broadcast(
      "price_alerts_#{alert.flight_filter&.user_id || 'anonymous'}",
      {
        type: 'price_break_alert',
        alert_id: alert.id,
        title: browser_content[:title],
        body: browser_content[:body],
        data: browser_content[:data],
        timestamp: Time.current.iso8601,
        urgency: smart_content[:urgency]
      }
    )
    
    # Record successful delivery
    alert.add_notification_record('browser', browser_content[:title], true)
    
    Rails.logger.info "Browser alert delivered for alert #{alert.id}"
  rescue => e
    Rails.logger.error "Browser delivery failed for alert #{alert.id}: #{e.message}"
    alert.add_notification_record('browser', "Delivery failed: #{e.message}", false)
    raise
  end

  # Generate smart email content
  def generate_smart_email_content(alert, smart_content)
    {
      subject: smart_content[:title],
      body: {
        greeting: "Hello #{alert.flight_filter&.user&.first_name || 'there'},",
        alert_content: smart_content[:body],
        call_to_action: smart_content[:call_to_action],
        context: smart_content[:context],
        booking_recommendation: smart_content[:booking_recommendation],
        urgency: smart_content[:urgency],
        confidence_score: smart_content[:confidence_score],
        footer: generate_email_footer(alert)
      },
      template: determine_email_template(smart_content[:urgency])
    }
  end

  # Generate smart push content
  def generate_smart_push_content(alert, smart_content)
    {
      title: smart_content[:title],
      body: smart_content[:body][:urgency_message] || "Price drop detected for #{alert.route_description}",
      data: {
        alert_id: alert.id,
        route: alert.route_description,
        current_price: alert.current_price,
        target_price: alert.target_price,
        savings_amount: alert.price_drop_amount,
        urgency: smart_content[:urgency],
        booking_url: generate_booking_url(alert)
      },
      icon: determine_push_icon(smart_content[:urgency]),
      badge: 1,
      sound: determine_push_sound(smart_content[:urgency])
    }
  end

  # Generate smart SMS content
  def generate_smart_sms_content(alert, smart_content)
    urgency_emoji = case smart_content[:urgency]
                   when :urgent then "🚨"
                   when :significant then "🎉"
                   when :minor then "💰"
                   else "📱"
                   end
    
    "#{urgency_emoji} PriceBreak: #{alert.route_description} dropped to $#{alert.current_price} (save $#{alert.price_drop_amount}). #{smart_content[:call_to_action][:primary]} - #{generate_booking_url(alert)}"
  end

  # Generate smart browser content
  def generate_smart_browser_content(alert, smart_content)
    {
      title: smart_content[:title],
      body: smart_content[:body][:urgency_message] || "Price drop detected",
      data: {
        alert_id: alert.id,
        route: alert.route_description,
        current_price: alert.current_price,
        target_price: alert.target_price,
        savings_amount: alert.price_drop_amount,
        savings_percentage: alert.price_drop_percentage_calculated,
        urgency: smart_content[:urgency],
        confidence_score: smart_content[:confidence_score],
        booking_url: generate_booking_url(alert),
        context: smart_content[:context]
      },
      icon: determine_browser_icon(smart_content[:urgency]),
      badge: 1,
      tag: "price_alert_#{alert.id}",
      require_interaction: smart_content[:urgency] == :urgent
    }
  end

  # Generate email content (legacy method)
  def generate_email_content(alert)
    filter = alert.flight_filter
    savings_amount = alert.price_drop_amount
    savings_percentage = alert.price_drop_percentage_calculated
    
    {
      subject: "🎉 Price Break Alert: #{alert.route_description} - Save $#{savings_amount}",
      body: {
        greeting: "Great news! We found a price break for your flight search.",
        route: alert.route_description,
        original_price: "$#{filter&.target_price}",
        current_price: "$#{alert.current_price}",
        savings: {
          amount: "$#{savings_amount}",
          percentage: "#{savings_percentage}%"
        },
        departure_date: alert.departure_date&.strftime('%B %d, %Y'),
        confidence_score: "#{(alert.alert_quality_score * 100).round}%",
        booking_links: generate_booking_links(alert),
        next_steps: [
          "Book quickly - this price may not last long!",
          "Check multiple booking sites for the best deal",
          "Consider flexible dates if this doesn't work"
        ]
      }
    }
  end

  # Generate push notification content
  def generate_push_content(alert)
    savings_amount = alert.price_drop_amount
    
    {
      title: "Price Break! Save $#{savings_amount}",
      body: "#{alert.route_description} dropped to $#{alert.current_price}",
      data: {
        alert_id: alert.id,
        route: alert.route_description,
        current_price: alert.current_price,
        savings_amount: savings_amount,
        booking_url: generate_booking_links(alert).first
      }
    }
  end

  # Generate SMS content
  def generate_sms_content(alert)
    savings_amount = alert.price_drop_amount
    
    "PriceBreak Alert: #{alert.route_description} dropped to $#{alert.current_price} (save $#{savings_amount}). Book now! #{generate_booking_links(alert).first}"
  end

  # Generate browser notification content
  def generate_browser_content(alert)
    savings_amount = alert.price_drop_amount
    
    {
      title: "🎉 Price Break Alert!",
      body: "#{alert.route_description} - Save $#{savings_amount}",
      data: {
        alert_id: alert.id,
        route: alert.route_description,
        current_price: alert.current_price,
        target_price: alert.target_price,
        savings_amount: savings_amount,
        savings_percentage: alert.price_drop_percentage_calculated,
        confidence_score: alert.alert_quality_score,
        booking_links: generate_booking_links(alert)
      }
    }
  end

  # Generate booking URL for the alert
  def generate_booking_url(alert)
    filter = alert.flight_filter
    return nil unless filter
    
    # Generate search URL for popular booking sites
    search_params = {
      origin: filter.origin_airports_array&.first,
      destination: filter.destination_airports_array&.first,
      departure_date: alert.departure_date&.strftime('%Y-%m-%d'),
      return_date: alert.return_date&.strftime('%Y-%m-%d'),
      passengers: filter.passenger_count || 1
    }
    
    "https://www.google.com/flights?q=#{search_params[:origin]}+to+#{search_params[:destination]}+#{search_params[:departure_date]}"
  end

  # Generate booking links for the alert (legacy method)
  def generate_booking_links(alert)
    filter = alert.flight_filter
    return [] unless filter
    
    # Generate search URLs for popular booking sites
    search_params = {
      origin: filter.origin_airports_array&.first,
      destination: filter.destination_airports_array&.first,
      departure_date: alert.departure_date&.strftime('%Y-%m-%d'),
      return_date: alert.return_date&.strftime('%Y-%m-%d'),
      passengers: filter.passenger_count || 1
    }
    
    [
      "https://www.google.com/flights?q=#{search_params[:origin]}+to+#{search_params[:destination]}+#{search_params[:departure_date]}",
      "https://www.kayak.com/flights/#{search_params[:origin]}-#{search_params[:destination]}/#{search_params[:departure_date]}",
      "https://www.expedia.com/Flights-Search?mode=search&trip=roundtrip&leg1=#{search_params[:origin]},#{search_params[:destination]},#{search_params[:departure_date]}"
    ]
  end

  # Generate email footer
  def generate_email_footer(alert)
    {
      unsubscribe_url: generate_unsubscribe_url(alert),
      manage_alerts_url: generate_manage_alerts_url,
      support_email: 'support@pricebreak.com',
      company_name: 'PriceBreak'
    }
  end

  # Generate unsubscribe URL
  def generate_unsubscribe_url(alert)
    Rails.application.routes.url_helpers.unsubscribe_url(
      token: generate_unsubscribe_token(alert),
      host: Rails.application.config.action_mailer.default_url_options[:host]
    )
  end

  # Generate manage alerts URL
  def generate_manage_alerts_url
    Rails.application.routes.url_helpers.flight_alerts_url(
      host: Rails.application.config.action_mailer.default_url_options[:host]
    )
  end

  # Generate unsubscribe token
  def generate_unsubscribe_token(alert)
    "unsubscribe_#{alert.id}_#{Time.current.to_i}"
  end

  # Determine email template based on urgency
  def determine_email_template(urgency)
    case urgency
    when :urgent then 'urgent_price_alert'
    when :significant then 'significant_price_alert'
    when :minor then 'minor_price_alert'
    else 'standard_price_alert'
    end
  end

  # Determine push notification icon
  def determine_push_icon(urgency)
    case urgency
    when :urgent then 'urgent_alert'
    when :significant then 'price_drop'
    when :minor then 'price_update'
    else 'notification'
    end
  end

  # Determine push notification sound
  def determine_push_sound(urgency)
    case urgency
    when :urgent then 'urgent_alert.wav'
    when :significant then 'price_drop.wav'
    else 'default.wav'
    end
  end

  # Determine browser notification icon
  def determine_browser_icon(urgency)
    case urgency
    when :urgent then '/icons/urgent-alert.png'
    when :significant then '/icons/price-drop.png'
    when :minor then '/icons/price-update.png'
    else '/icons/notification.png'
    end
  end

  # Send push notification (placeholder - integrate with your push service)
  def send_push_notification(alert, content)
    # This would integrate with Firebase Cloud Messaging, OneSignal, etc.
    # For now, just log the notification
    Rails.logger.info "Push notification would be sent: #{content[:title]} - #{content[:body]}"
  end

  # Send SMS notification (placeholder - integrate with your SMS service)
  def send_sms_notification(alert, content)
    # This would integrate with Twilio, AWS SNS, etc.
    # For now, just log the SMS
    Rails.logger.info "SMS would be sent: #{content}"
  end

  # Class method to deliver all pending alerts
  def self.deliver_pending_alerts
    pending_alerts = FlightAlert.where(status: 'triggered')
                               .where('created_at >= ?', 1.hour.ago)
                               .where('notification_history IS NULL OR notification_history = ?', '[]')
    
    Rails.logger.info "Delivering #{pending_alerts.count} pending alerts"
    
    pending_alerts.find_each do |alert|
      AlertDeliveryJob.perform_later(alert.id, :all)
    end
  end

  # Class method to get delivery statistics
  def self.delivery_stats
    recent_alerts = FlightAlert.where('created_at >= ?', 24.hours.ago)
    
    {
      total_alerts: recent_alerts.count,
      delivered_alerts: recent_alerts.joins("LEFT JOIN LATERAL jsonb_array_elements(notification_history) AS n ON true")
                                   .where("n->>'success' = 'true'")
                                   .count,
      failed_deliveries: recent_alerts.joins("LEFT JOIN LATERAL jsonb_array_elements(notification_history) AS n ON true")
                                     .where("n->>'success' = 'false'")
                                     .count,
      delivery_methods: {
        email: recent_alerts.where("notification_history::text LIKE '%email%'").count,
        push: recent_alerts.where("notification_history::text LIKE '%push%'").count,
        sms: recent_alerts.where("notification_history::text LIKE '%sms%'").count,
        browser: recent_alerts.where("notification_history::text LIKE '%browser%'").count
      }
    }
  end
end



