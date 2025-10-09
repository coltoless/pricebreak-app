class NotificationService
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :alert, type: Object
  attribute :user, type: Object
  attribute :channels, type: Array, default: []
  attribute :content, type: Hash, default: {}
  attribute :priority, type: String, default: 'normal'

  # Rate limiting constants
  MAX_NOTIFICATIONS_PER_HOUR = 10
  MAX_NOTIFICATIONS_PER_DAY = 50
  COOLDOWN_PERIOD = 1.hour

  # Channel priorities
  CHANNEL_PRIORITIES = {
    'browser' => 1,  # Highest priority - immediate
    'push' => 2,     # High priority - mobile
    'email' => 3,    # Medium priority - reliable
    'sms' => 4       # Lowest priority - expensive
  }.freeze

  def initialize(alert, options = {})
    @alert = alert
    @user = alert.flight_filter&.user || alert.user
    @channels = determine_channels(options[:channels])
    @content = options[:content] || {}
    @priority = options[:priority] || 'normal'
  end

  # Main method to send notifications across all channels
  def send_notifications
    return { success: false, error: 'No valid channels' } if channels.empty?
    return { success: false, error: 'Rate limited' } if rate_limited?

    results = { success: true, channels: [], errors: [] }

    # Sort channels by priority
    sorted_channels = channels.sort_by { |channel| CHANNEL_PRIORITIES[channel] || 999 }

    sorted_channels.each do |channel|
      begin
        result = send_to_channel(channel)
        results[:channels] << { channel: channel, success: true, result: result }
      rescue => e
        results[:errors] << { channel: channel, error: e.message }
        results[:success] = false if is_critical_channel?(channel)
      end
    end

    # Record delivery attempt
    record_delivery_attempt(results)

    results
  end

  # Send notification to specific channel
  def send_to_channel(channel)
    case channel
    when 'email'
      send_email_notification
    when 'push'
      send_push_notification
    when 'sms'
      send_sms_notification
    when 'browser'
      send_browser_notification
    else
      raise "Unknown channel: #{channel}"
    end
  end

  # Send email notification
  def send_email_notification
    email_content = generate_email_content
    
    PriceAlertMailer.price_break_alert(alert, email_content).deliver_now
    
    {
      method: 'email',
      subject: email_content[:subject],
      delivered_at: Time.current,
      success: true
    }
  end

  # Send push notification
  def send_push_notification
    push_content = generate_push_content
    
    # Send via Firebase Cloud Messaging or similar
    send_firebase_notification(push_content)
    
    {
      method: 'push',
      title: push_content[:title],
      delivered_at: Time.current,
      success: true
    }
  end

  # Send SMS notification
  def send_sms_notification
    sms_content = generate_sms_content
    
    # Send via Twilio or similar
    send_twilio_sms(sms_content)
    
    {
      method: 'sms',
      message: sms_content,
      delivered_at: Time.current,
      success: true
    }
  end

  # Send browser notification via ActionCable
  def send_browser_notification
    browser_content = generate_browser_content
    
    ActionCable.server.broadcast(
      "price_alerts_#{user&.id || 'anonymous'}",
      {
        type: 'price_break_alert',
        alert_id: alert.id,
        title: browser_content[:title],
        body: browser_content[:body],
        data: browser_content[:data],
        timestamp: Time.current.iso8601,
        priority: priority
      }
    )
    
    {
      method: 'browser',
      title: browser_content[:title],
      delivered_at: Time.current,
      success: true
    }
  end

  # Generate email content
  def generate_email_content
    intelligence = AlertIntelligenceService.new(alert, alert.current_price)
    smart_content = intelligence.generate_alert_content
    
    {
      subject: smart_content[:title],
      body: {
        greeting: "Hello #{user&.first_name || 'there'},",
        alert_content: smart_content[:body],
        call_to_action: smart_content[:call_to_action],
        context: smart_content[:context],
        booking_recommendation: smart_content[:booking_recommendation],
        footer: generate_email_footer
      },
      template: determine_email_template(smart_content[:urgency])
    }
  end

  # Generate push notification content
  def generate_push_content
    intelligence = AlertIntelligenceService.new(alert, alert.current_price)
    smart_content = intelligence.generate_alert_content
    
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
        booking_url: generate_booking_url
      },
      icon: determine_push_icon(smart_content[:urgency]),
      badge: 1,
      sound: determine_push_sound(smart_content[:urgency])
    }
  end

  # Generate SMS content
  def generate_sms_content
    intelligence = AlertIntelligenceService.new(alert, alert.current_price)
    smart_content = intelligence.generate_alert_content
    
    urgency_emoji = case smart_content[:urgency]
                   when :urgent then "🚨"
                   when :significant then "🎉"
                   when :minor then "💰"
                   else "📱"
                   end
    
    "#{urgency_emoji} PriceBreak: #{alert.route_description} dropped to $#{alert.current_price} (save $#{alert.price_drop_amount}). #{smart_content[:call_to_action][:primary]} - #{generate_booking_url}"
  end

  # Generate browser notification content
  def generate_browser_content
    intelligence = AlertIntelligenceService.new(alert, alert.current_price)
    smart_content = intelligence.generate_alert_content
    
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
        booking_url: generate_booking_url,
        context: smart_content[:context]
      },
      icon: determine_browser_icon(smart_content[:urgency]),
      badge: 1,
      tag: "price_alert_#{alert.id}",
      require_interaction: smart_content[:urgency] == :urgent
    }
  end

  # Determine which channels to use based on user preferences and alert settings
  def determine_channels(requested_channels = nil)
    return requested_channels if requested_channels.present?
    
    # Get user preferences
    user_preferences = user&.notification_preferences || {}
    
    # Get alert-specific preferences
    alert_preferences = alert.flight_filter&.notification_methods || {}
    
    # Default channels
    default_channels = ['email', 'browser']
    
    # Merge preferences (alert-specific overrides user preferences)
    enabled_channels = default_channels.select do |channel|
      alert_preferences[channel] != false && user_preferences[channel] != false
    end
    
    # Add push if user has mobile app
    if user&.has_mobile_app? && (alert_preferences['push'] != false && user_preferences['push'] != false)
      enabled_channels << 'push'
    end
    
    # Add SMS for urgent alerts if user has phone number
    if alert.alert_quality_score && alert.alert_quality_score > 0.8 && user&.phone_number.present?
      enabled_channels << 'sms'
    end
    
    enabled_channels.uniq
  end

  # Check if user is rate limited
  def rate_limited?
    return false unless user
    
    recent_count = user.notification_history
                      .where('created_at > ?', 1.hour.ago)
                      .count
    
    recent_count >= MAX_NOTIFICATIONS_PER_HOUR
  end

  # Check if channel is critical for delivery
  def is_critical_channel?(channel)
    ['email', 'browser'].include?(channel)
  end

  # Record delivery attempt for analytics
  def record_delivery_attempt(results)
    delivery_record = {
      timestamp: Time.current,
      channels: results[:channels].map { |c| c[:channel] },
      success: results[:success],
      errors: results[:errors],
      priority: priority,
      alert_id: alert.id
    }
    
    # Update user's notification history
    if user
      user.notification_history ||= []
      user.notification_history << delivery_record
      user.save!
    end
    
    # Update alert's notification history
    alert.add_notification_record(
      'multi_channel',
      "Delivered to #{results[:channels].count} channels",
      results[:success]
    )
  end

  # Generate booking URL
  def generate_booking_url
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

  # Generate email footer
  def generate_email_footer
    {
      unsubscribe_url: generate_unsubscribe_url,
      manage_alerts_url: generate_manage_alerts_url,
      support_email: 'support@pricebreak.com',
      company_name: 'PriceBreak'
    }
  end

  # Generate unsubscribe URL
  def generate_unsubscribe_url
    Rails.application.routes.url_helpers.unsubscribe_url(
      token: generate_unsubscribe_token,
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
  def generate_unsubscribe_token
    # This would generate a secure token for unsubscribe
    # For now, return a placeholder
    "unsubscribe_#{alert.id}_#{Time.current.to_i}"
  end

  # Send Firebase notification (placeholder)
  def send_firebase_notification(content)
    # This would integrate with Firebase Cloud Messaging
    Rails.logger.info "Firebase notification would be sent: #{content[:title]} - #{content[:body]}"
    
    {
      message_id: "firebase_#{SecureRandom.hex(8)}",
      success: true
    }
  end

  # Send Twilio SMS (placeholder)
  def send_twilio_sms(content)
    # This would integrate with Twilio
    Rails.logger.info "SMS would be sent to #{user&.phone_number}: #{content}"
    
    {
      message_sid: "twilio_#{SecureRandom.hex(8)}",
      success: true
    }
  end

  # Class method to send digest notifications
  def self.send_digest_notifications(user_id)
    user = User.find(user_id)
    return unless user
    
    # Get minor alerts from the last 24 hours that haven't been sent
    minor_alerts = user.flight_alerts
                      .where(status: 'triggered')
                      .where('created_at > ?', 24.hours.ago)
                      .where('alert_quality_score < ?', 0.8)
    
    return if minor_alerts.empty?
    
    # Send digest email
    PriceAlertMailer.price_digest(user, minor_alerts).deliver_now
    
    {
      success: true,
      alerts_count: minor_alerts.count,
      method: 'digest_email'
    }
  end

  # Class method to get delivery statistics
  def self.delivery_stats(timeframe = 24.hours)
    recent_deliveries = NotificationDelivery
                       .where('created_at > ?', Time.current - timeframe)
    
    {
      total_deliveries: recent_deliveries.count,
      successful_deliveries: recent_deliveries.where(success: true).count,
      failed_deliveries: recent_deliveries.where(success: false).count,
      by_channel: recent_deliveries.group(:channel).count,
      by_priority: recent_deliveries.group(:priority).count,
      average_delivery_time: recent_deliveries.average(:delivery_time_ms)
    }
  end
end
