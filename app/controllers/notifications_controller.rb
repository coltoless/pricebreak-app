class NotificationsController < ApplicationController
  def create
    @subscriber = Subscriber.new(email: params[:email])

    if @subscriber.save
      redirect_to root_path, notice: "Thanks! We'll notify you when we launch."
    else
      redirect_to root_path, alert: @subscriber.errors.full_messages.first
    end
  end
end 