class NotificationsController < ApplicationController
  def create
    # For now, just redirect back with a success message
    # TODO: Implement actual email collection and storage
    redirect_to root_path, notice: "Thanks! We'll notify you when we launch."
  end
end 