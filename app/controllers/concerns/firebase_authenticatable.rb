module FirebaseAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_firebase_user!
  end

  private

  def authenticate_firebase_user!
    @current_user = find_or_create_user_from_firebase_token
    unless @current_user
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end

  def find_or_create_user_from_firebase_token
    return nil unless firebase_token_present?

    begin
      # Verify the Firebase ID token
      decoded_token = verify_firebase_token
      return nil unless decoded_token

      firebase_uid = decoded_token['uid']
      email = decoded_token['email']
      name = decoded_token['name'] || email

      # Find existing user by Firebase UID
      user = User.find_by(firebase_uid: firebase_uid)
      
      if user
        # Update user info if needed
        user.update(
          email: email,
          name: name
        ) if user.email != email || user.name != name
      else
        # Create new user
        user = User.create!(
          firebase_uid: firebase_uid,
          email: email,
          name: name
        )
      end

      user
    rescue => e
      Rails.logger.error "Firebase authentication error: #{e.message}"
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

  def require_firebase_user!
    unless current_user
      render json: { error: 'User not found' }, status: :not_found
    end
  end
end

