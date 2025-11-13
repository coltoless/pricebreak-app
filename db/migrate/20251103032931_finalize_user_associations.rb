class FinalizeUserAssociations < ActiveRecord::Migration[8.0]
  def up
    # First, handle any existing records without user_id
    # Set them to the first user if available, or create a default user
    default_user = User.first
    
    if default_user.nil?
      # Create a default user if none exists (for development/testing)
      default_user = User.create!(
        email: 'admin@pricebreak.com',
        password: 'password123',
        password_confirmation: 'password123'
      )
    end
    
    # Update all flight_filters without user_id
    execute <<-SQL
      UPDATE flight_filters 
      SET user_id = #{default_user.id}
      WHERE user_id IS NULL
    SQL
    
    # Update all flight_alerts without user_id
    execute <<-SQL
      UPDATE flight_alerts 
      SET user_id = #{default_user.id}
      WHERE user_id IS NULL
    SQL
    
    # Now make user_id NOT NULL
    change_column_null :flight_filters, :user_id, false
    change_column_null :flight_alerts, :user_id, false
    
    # Remove the temporary comments
    execute "COMMENT ON COLUMN flight_filters.user_id IS NULL"
    execute "COMMENT ON COLUMN flight_alerts.user_id IS NULL"
  end

  def down
    # Revert to nullable for testing
    change_column_null :flight_filters, :user_id, true
    change_column_null :flight_alerts, :user_id, true
    
    # Restore comments
    execute "COMMENT ON COLUMN flight_filters.user_id IS 'Temporarily nullable for Phase 1 testing. Will be made NOT NULL in Phase 2.'"
    execute "COMMENT ON COLUMN flight_alerts.user_id IS 'Temporarily nullable for Phase 1 testing. Will be made NOT NULL in Phase 2.'"
  end
end
