# Firebase Admin SDK Configuration
# This initializer will be loaded after all gems are loaded

Rails.application.config.after_initialize do
  begin
    # Only load Firebase if the gem is available
    if defined?(FirebaseAdmin)
      if Rails.application.credentials.firebase.present?
        FirebaseAdmin.configure do |config|
          config.project_id = Rails.application.credentials.firebase[:project_id]
          config.private_key_id = Rails.application.credentials.firebase[:private_key_id]
          config.private_key = Rails.application.credentials.firebase[:private_key]
          config.client_email = Rails.application.credentials.firebase[:client_email]
          config.client_id = Rails.application.credentials.firebase[:client_id]
          config.auth_uri = Rails.application.credentials.firebase[:auth_uri]
          config.token_uri = Rails.application.credentials.firebase[:token_uri]
          config.auth_provider_x509_cert_url = Rails.application.credentials.firebase[:auth_provider_x509_cert_url]
          config.client_x509_cert_url = Rails.application.credentials.firebase[:client_x509_cert_url]
        end
        
        Rails.logger.info "Firebase Admin SDK configured successfully"
      else
        Rails.logger.warn "Firebase credentials not found. Firebase authentication will not work."
        Rails.logger.info "To configure Firebase, run: rails credentials:edit"
        Rails.logger.info "Add your Firebase service account credentials under the 'firebase:' key"
      end
    else
      Rails.logger.warn "Firebase Admin SDK gem not loaded. Firebase authentication will not work."
    end
  rescue => e
    Rails.logger.error "Failed to configure Firebase Admin SDK: #{e.message}"
  end
end
