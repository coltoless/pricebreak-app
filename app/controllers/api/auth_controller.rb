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
          preferred_airports: current_user.preferred_airports || []
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
    params.permit(:email_subscription, preferred_airports: [])
  end
end

