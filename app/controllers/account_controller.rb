class AccountController < ApplicationController
  # Skip Firebase authentication for HTML views - we'll handle auth client-side
  skip_before_action :redirect_to_coming_soon
  
  def index
    # Account dashboard - user data will be fetched client-side via API
  end
  
  def settings
    # Account settings page
  end
end

