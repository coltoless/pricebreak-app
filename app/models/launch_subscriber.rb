class LaunchSubscriber < ApplicationRecord
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  
  after_create :sync_to_mailchimp
  after_destroy :unsubscribe_from_mailchimp

  private

  def sync_to_mailchimp
    return if Rails.env.test?
    
    mailchimp = MailchimpService.new
    mailchimp.subscribe(email)
  end

  def unsubscribe_from_mailchimp
    return if Rails.env.test?
    
    mailchimp = MailchimpService.new
    mailchimp.unsubscribe(email)
  end
end
