class Api::AuthController < ApplicationController
  include FirebaseAuthenticatable

  # Skip CSRF token verification for API endpoints
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_firebase_user!, only: [ :login, :register ]

  # POST /api/auth/login
  def login
    # Verify Firebase token and create/find user in our database
    begin
      user = find_or_create_user_from_firebase_token
      
      if user
        render json: {
          user: {
            id: user.id,
            email: user.email,
            name: user.name,
            firebase_uid: user.firebase_uid
          }
        }
      else
        Rails.logger.error "Failed to authenticate: user is nil"
        render json: { error: "Authentication failed. Invalid token or user creation failed." }, status: :unauthorized
      end
    rescue => e
      Rails.logger.error "Login error: #{e.message}"
      Rails.logger.error e.backtrace.first(10).join("\n")
      render json: { error: "Authentication failed. #{e.message}" }, status: :unprocessable_entity
    end
  end

  # POST /api/auth/register
  def register
    # Verify Firebase token and create user account
    user = find_or_create_user_from_firebase_token
    
    if user
      render json: {
        message: "User registered successfully",
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          firebase_uid: user.firebase_uid
        }
      }
    else
      render json: { error: "Registration failed. Invalid token or user creation failed." }, status: :unprocessable_entity
    end
  end

  # DELETE /api/auth/logout
  def logout
    # Logout is handled on the frontend by Firebase
    # This endpoint just confirms the user is logged out
    render json: { message: "Logged out successfully" }
  end

  # GET /api/auth/me
  def me
    require_firebase_user!
    
    render json: {
      user: {
        id: current_user.id,
        email: current_user.email,
        name: current_user.name,
        firebase_uid: current_user.firebase_uid,
        email_subscription: current_user.email_subscription || false,
        preferred_airports: current_user.preferred_airports || [],
        created_at: current_user.created_at,
        updated_at: current_user.updated_at
      }
    }
  end

  # GET /api/auth/dashboard
  def dashboard
    require_firebase_user!
    
    # Get user preferences
    preferences = {
      email: current_user.email,
      name: current_user.name,
      home_city: current_user.home_city,
      currency: current_user.currency || 'USD',
      language: current_user.language || 'en',
      timezone: current_user.timezone || 'UTC',
      email_subscription: current_user.email_subscription || false,
      preferred_airports: current_user.preferred_airports || []
    }
    
    # Get active price alerts
    active_alerts = current_user.flight_alerts.active.order(created_at: :desc).limit(50).map do |alert|
      {
        id: alert.id,
        origin: alert.origin,
        destination: alert.destination,
        departure_date: alert.departure_date,
        return_date: alert.return_date,
        target_price: alert.target_price,
        current_price: alert.current_price,
        status: alert.status,
        notification_method: alert.notification_method,
        created_at: alert.created_at,
        is_urgent: alert.is_urgent?,
        route_description: alert.route_description,
        wedding_mode: alert.wedding_mode,
        wedding_date: alert.wedding_date
      }
    end
    
    # Get all alerts (for stats)
    all_alerts = current_user.flight_alerts.order(created_at: :desc)
    alerts_stats = {
      total: all_alerts.count,
      active: all_alerts.where(status: 'active').count,
      triggered: all_alerts.where(status: 'triggered').count,
      paused: all_alerts.where(status: 'paused').count,
      expired: all_alerts.where(status: 'expired').count
    }
    
    # Get saved searches (flight filters)
    saved_searches = current_user.flight_filters.order(created_at: :desc).limit(50).map do |filter|
      {
        id: filter.id,
        name: filter.name,
        description: filter.description,
        origin_airports: filter.origin_airports_array,
        destination_airports: filter.destination_airports_array,
        trip_type: filter.trip_type,
        departure_dates: filter.departure_dates_array,
        return_dates: filter.return_dates_array,
        is_active: filter.is_active,
        created_at: filter.created_at,
        route_description: filter.route_description,
        passenger_count: filter.passenger_count,
        target_price: filter.target_price,
        cabin_class: filter.cabin_class
      }
    end
    
    # Get future trips (flight filters with future dates)
    future_trips = current_user.flight_filters.active.select do |filter|
      dates = filter.departure_dates_array
      dates.any? do |date_str|
        begin
          Date.parse(date_str) >= Date.current
        rescue
          false
        end
      end
    end.map do |filter|
      {
        id: filter.id,
        name: filter.name,
        description: filter.description,
        origin_airports: filter.origin_airports_array,
        destination_airports: filter.destination_airports_array,
        trip_type: filter.trip_type,
        departure_dates: filter.departure_dates_array,
        return_dates: filter.return_dates_array,
        created_at: filter.created_at,
        route_description: filter.route_description,
        passenger_count: filter.passenger_count,
        target_price: filter.target_price,
        cabin_class: filter.cabin_class,
        is_urgent: filter.is_urgent?
      }
    end.sort_by { |trip| 
      earliest_date = trip[:departure_dates].map { |d| Date.parse(d) rescue Date.today }.min
      earliest_date
    }
    
    # Generate suggested alerts based on user patterns
    suggested_alerts = generate_suggested_alerts(current_user)
    
    render json: {
      preferences: preferences,
      alerts: {
        active: active_alerts,
        stats: alerts_stats
      },
      saved_searches: saved_searches,
      future_trips: future_trips,
      suggested_alerts: suggested_alerts
    }
  end

  # PUT /api/auth/profile
  def update_profile
    require_firebase_user!
    
    if current_user.update(user_params)
      render json: {
        message: "Profile updated successfully",
        user: {
          id: current_user.id,
          email: current_user.email,
          name: current_user.name,
          firebase_uid: current_user.firebase_uid,
          email_subscription: current_user.email_subscription || false,
          preferred_airports: current_user.preferred_airports || []
        }
      }
    else
      render json: {
        error: "Profile update failed",
        errors: current_user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  # PUT /api/auth/preferences
  def update_preferences
    require_firebase_user!
    
    if current_user.update(preferences_params)
      render json: {
        message: "Preferences updated successfully",
        user: {
          id: current_user.id,
          email_subscription: current_user.email_subscription || false,
          preferred_airports: current_user.preferred_airports || [],
          home_city: current_user.home_city,
          currency: current_user.currency,
          language: current_user.language,
          timezone: current_user.timezone
        }
      }
    else
      render json: {
        error: "Preferences update failed",
        errors: current_user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def find_or_create_user_from_firebase_token
    unless firebase_token_present?
      Rails.logger.error "No Firebase token present in request"
      return nil
    end

    begin
      # Verify the Firebase ID token
      decoded_token = verify_firebase_token
      unless decoded_token
        Rails.logger.error "Token verification failed - decoded_token is nil"
        return nil
      end

      Rails.logger.info "Token verified successfully: #{decoded_token.keys.join(', ')}"
      
      firebase_uid = decoded_token["uid"] || decoded_token["localId"]
      email = decoded_token["email"]
      name = decoded_token["name"] || decoded_token["displayName"] || decoded_token["display_name"] || email.split("@").first
      
      Rails.logger.info "Extracted user info - UID: #{firebase_uid}, Email: #{email}, Name: #{name}"

      # Find existing user by Firebase UID
      user = User.find_by(firebase_uid: firebase_uid)
      
      if user
        # Update user info if needed
        update_attrs = {}
        update_attrs[:email] = email if user.email != email
        update_attrs[:name] = name if user.name != name
        
        user.update(update_attrs) if update_attrs.any?
      else
        # Check if user exists with same email (for migration)
        existing_user = User.find_by(email: email)
        
        if existing_user
          # Link existing account to Firebase
          existing_user.update(firebase_uid: firebase_uid, name: name) if existing_user.name != name || existing_user.firebase_uid != firebase_uid
          user = existing_user
        else
          # Create new user (skip password validation for Firebase users)
          user = User.new(
            firebase_uid: firebase_uid,
            email: email,
            name: name,
            password: Devise.friendly_token[0, 20] # Generate a random password for Devise
          )
          if user.save(validate: false)
            Rails.logger.info "User created successfully: #{user.id}"
          else
            Rails.logger.error "Failed to create user: #{user.errors.full_messages.join(', ')}"
            Rails.logger.error "User attributes: #{user.attributes.inspect}"
            return nil
          end
        end
      end

      user
    rescue => e
      Rails.logger.error "Firebase authentication error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      nil
    end
  end

  def firebase_token_present?
    request.headers['Authorization'].present? &&
    request.headers['Authorization'].start_with?('Bearer ')
  end

  def verify_firebase_token
    token = request.headers['Authorization'].gsub('Bearer ', '')
    return nil if token.blank?
    
    # Try Firebase Admin SDK first if available
    begin
      require 'firebase_admin' unless defined?(FirebaseAdmin)
      if defined?(FirebaseAdmin)
        return FirebaseAdmin.verify_id_token(token)
      end
    rescue LoadError
      # Admin SDK not available, will use REST API fallback
    rescue => e
      Rails.logger.warn "Firebase Admin SDK verification failed, trying REST API: #{e.message}"
    end
    
    # Fallback: Verify token using Firebase REST API
    verify_token_via_rest_api(token)
  end
  
  def verify_token_via_rest_api(token)
    project_id = ENV['FIREBASE_PROJECT_ID'] || 'pricebreak-8cec7'
    api_key = ENV['FIREBASE_API_KEY']
    
    unless api_key.present?
      Rails.logger.error "FIREBASE_API_KEY not set"
      return nil
    end
    
    url = "https://www.googleapis.com/identitytoolkit/v3/relyingparty/getAccountInfo?key=#{api_key}"
    
    begin
      require 'net/http'
      require 'json'
      require 'uri'
      
      Rails.logger.info "Verifying token via REST API..."
      
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 10
      
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = { idToken: token }.to_json
      
      response = http.request(request)
      
      Rails.logger.info "REST API response code: #{response.code}"
      
      if response.code == '200'
        data = JSON.parse(response.body)
        Rails.logger.info "REST API response data keys: #{data.keys.join(', ')}"
        
        if data['users']&.first
          user_data = data['users'].first
          Rails.logger.info "User data keys: #{user_data.keys.join(', ')}"
          
          result = {
            'uid' => user_data['localId'],
            'email' => user_data['email'],
            'name' => user_data['displayName'],
            'email_verified' => user_data['emailVerified'] || false
          }
          Rails.logger.info "Token verified successfully via REST API"
          return result
        else
          Rails.logger.error "Firebase REST API verification failed: No users in response. Response: #{data.inspect}"
          nil
        end
      else
        error_body = response.body rescue 'Unable to read response body'
        Rails.logger.error "Firebase REST API verification failed: #{response.code} - #{error_body}"
        nil
      end
    rescue => e
      Rails.logger.error "Firebase REST API verification error: #{e.message}"
      Rails.logger.error e.backtrace.first(10).join("\n") if e.backtrace
      nil
    end
  end

  def user_params
    params.require(:user).permit(:name)
  end
  
  def preferences_params
    params.permit(:email_subscription, :home_city, :currency, :language, :timezone, preferred_airports: [])
  end
  
  def generate_suggested_alerts(user)
    suggestions = []
    
    # Suggest alerts based on frequently searched routes
    frequent_routes = user.flight_filters
      .group_by { |f| "#{f.origin_airports_array.first}→#{f.destination_airports_array.first}" }
      .sort_by { |_, filters| -filters.count }
      .first(3)
    
    frequent_routes.each do |route, filters|
      next if filters.empty?
      
      filter = filters.first
      existing_alert = user.flight_alerts.active.find_by(
        origin: filter.origin_airports_array.first,
        destination: filter.destination_airports_array.first
      )
      
      next if existing_alert # Don't suggest if alert already exists
      
      suggestions << {
        type: 'frequent_route',
        reason: "You've searched this route #{filters.count} times",
        origin: filter.origin_airports_array.first,
        destination: filter.destination_airports_array.first,
        suggested_target_price: filter.target_price,
        priority: 'medium'
      }
    end
    
    # Suggest alerts for future trips without active alerts
    user.flight_filters.active.each do |filter|
      dates = filter.departure_dates_array
      future_dates = dates.select do |date_str|
        begin
          Date.parse(date_str) >= Date.current
        rescue
          false
        end
      end
      
      next if future_dates.empty?
      
      origin = filter.origin_airports_array.first
      destination = filter.destination_airports_array.first
      
      existing_alert = user.flight_alerts.active.find_by(
        origin: origin,
        destination: destination
      )
      
      next if existing_alert
      
      suggestions << {
        type: 'future_trip',
        reason: "You have a planned trip but no active alert",
        origin: origin,
        destination: destination,
        departure_date: future_dates.first,
        suggested_target_price: filter.target_price,
        priority: filter.is_urgent? ? 'high' : 'medium'
      }
    end
    
    suggestions.uniq { |s| "#{s[:origin]}#{s[:destination]}" }
  end
end

