class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :redirect_to_coming_soon

  private

  def redirect_to_coming_soon
    return if controller_name == 'home' && action_name == 'index'
    return if controller_name == 'notifications' && action_name == 'create'
    return if controller_path.start_with?('dev/')
    
    redirect_to root_path
  end
end
