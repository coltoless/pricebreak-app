class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :redirect_to_coming_soon

  private

  def redirect_to_coming_soon
    return if controller_name == 'home' && action_name == 'index'
    return if controller_name == 'notifications' && action_name == 'create'
    return if controller_name == 'launch_subscribers' && action_name == 'create'
    # Allow Devise authentication controllers
    return if controller_path.start_with?('devise/')
    # Allow Firebase authentication
    return if controller_name == 'auth'
    # Allow Account dashboard
    return if controller_name == 'account'
    # ENABLED for local development
    return if controller_name == 'flight_filters'
    return if controller_name == 'flight_alerts'
    return if controller_name == 'flight_dashboard'
    return if controller_path.start_with?('dev/')
    return if controller_path.start_with?('api/')
    return if controller_path.start_with?('analytics/')
    return if controller_path.start_with?('monitoring/')
    
    # Comment out flight filters access for coming soon mode (production)
    # return if controller_name == 'flight_filters'
    # return if controller_path.start_with?('api/')
    
    redirect_to root_path
  end
end
