class Api::AuthController < ApplicationController
  include FirebaseAuthenticatable
  
  skip_before_action :authenticate_firebase_user!, only: [:login, :register]
  
  # POST /api/auth/login
  def login
    # This endpoint is for client-side Firebase authentication
    # The actual authentication happens on the frontend with Firebase SDK
    # This just returns the current user info after successful auth
    if current_user
      render json: {
        user: {
          id: current_user.id,
          email: current_user.email,
          name: current_user.name,
          firebase_uid: current_user.firebase_uid
        }
      }
    else
      render json: { error: 'Not authenticated' }, status: :unauthorized
    end
  end

  # POST /api/auth/register
  def register
    # Similar to login, registration happens on frontend
    # This endpoint just ensures the user exists in our database
    if current_user
      render json: {
        message: 'User registered successfully',
        user: {
          id: current_user.id,
          email: current_user.email,
          name: current_user.name,
          firebase_uid: current_user.firebase_uid
        }
      }
    else
      render json: { error: 'Registration failed' }, status: :unprocessable_entity
    end
  end

  # DELETE /api/auth/logout
  def logout
    # Logout is handled on the frontend by Firebase
    # This endpoint just confirms the user is logged out
    render json: { message: 'Logged out successfully' }
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
        message: 'Profile updated successfully',
        user: {
          id: current_user.id,
          email: current_user.email,
          name: current_user.name,
          firebase_uid: current_user.firebase_uid
        }
      }
    else
      render json: { 
        error: 'Profile update failed',
        errors: current_user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name)
  end
end

