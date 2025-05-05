class LaunchSubscribersController < ApplicationController
  def create
    @subscriber = LaunchSubscriber.new(email: params[:email])
    
    if @subscriber.save
      flash[:success] = "Thanks for your interest! We'll notify you when we launch."
    else
      if @subscriber.errors[:email].include?("has already been taken")
        flash[:error] = "This email is already registered. We'll notify you when we launch!"
      elsif @subscriber.errors[:email].include?("is invalid")
        flash[:error] = "Please enter a valid email address."
      else
        flash[:error] = "Sorry, there was an error saving your email. Please try again."
      end
    end
    
    redirect_to root_path
  end
end 