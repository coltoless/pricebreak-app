class LaunchSubscribersController < ApplicationController
  def create
    @subscriber = LaunchSubscriber.new(email: params[:email])
    
    if @subscriber.save
      flash[:success] = "Thanks for your interest! We'll notify you when we launch."
    else
      flash[:error] = "Sorry, there was an error saving your email."
    end
    
    redirect_to root_path
  end
end 