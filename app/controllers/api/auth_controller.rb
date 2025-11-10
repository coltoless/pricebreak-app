class Api::AuthController < ApplicationController
  include FirebaseAuthenticatable

  skip_before_action :authenticate_firebase_user!, only: [ :login, :register ]

  # POST /api/auth/login
  def login
    # Verify Firebase token and create/find user in our database
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
      render json: { error: "Authentication failed. Invalid token." }, status: :unauthorized
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
          firebase_uid: current_user.firebase_uid
        }
      }
    else
      render json: {
        error: "Profile update failed",
        errors: current_user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def find_or_create_user_from_firebase_token
    return nil unless firebase_token_present?

    begin
      # Verify the Firebase ID token
      decoded_token = verify_firebase_token
      return nil unless decoded_token

      firebase_uid = decoded_token["uid"]
      email = decoded_token["email"]
      name = decoded_token["name"] || decoded_token["display_name"] || email.split("@").first

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
          # Create new user
          user = User.create!(
            firebase_uid: firebase_uid,
            email: email,
            name: name
          )
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
    return nil unless defined?(FirebaseAdmin)

    token = request.headers['Authorization'].gsub('Bearer ', '')
    
    begin
      # Verify the token with Firebase Admin SDK
      FirebaseAdmin.verify_id_token(token)
    rescue => e
      Rails.logger.error "Firebase token verification failed: #{e.message}"
      nil
    end
  end

  def user_params
    params.require(:user).permit(:name)
  end
end

