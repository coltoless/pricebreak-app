class LaunchSubscribersController < ApplicationController
  # Skip CSRF verification for API-style requests if needed
  # but keep it enabled for form submissions
  
  def create
    email = params[:email]&.strip&.downcase
    
    if email.blank?
      flash[:error] = "Please enter an email address."
      redirect_to root_path and return
    end
    
    @subscriber = LaunchSubscriber.new(email: email)
    
    if @subscriber.save
      flash[:success] = "🎉 Thanks for signing up! We'll notify you when we launch."
      Rails.logger.info "New subscriber: #{email}"
    else
      if @subscriber.errors[:email].include?("has already been taken")
        flash[:success] = "You're already on the list! We'll notify you when we launch."
      elsif @subscriber.errors[:email].include?("is invalid")
        flash[:error] = "Please enter a valid email address."
      else
        error_messages = @subscriber.errors.full_messages.join(", ")
        flash[:error] = "Sorry, there was an error. Please try again."
        Rails.logger.error "Failed to save subscriber #{email}: #{error_messages}"
      end
    end
    
    redirect_to root_path
  rescue => e
    flash[:error] = "An unexpected error occurred. Please try again."
    Rails.logger.error "Exception in LaunchSubscribersController#create: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    redirect_to root_path
  end
end 