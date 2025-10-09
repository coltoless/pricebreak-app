class MakeUserIdNullableForPhase1Testing < ActiveRecord::Migration[8.0]
  def change
    # Make user_id nullable for Phase 1 testing
    # This allows testing the models without user associations
    change_column_null :flight_filters, :user_id, true
    change_column_null :flight_alerts, :user_id, true
    
    # Add a comment to document this is temporary for Phase 1
    execute "COMMENT ON COLUMN flight_filters.user_id IS 'Temporarily nullable for Phase 1 testing. Will be made NOT NULL in Phase 2.'"
    execute "COMMENT ON COLUMN flight_alerts.user_id IS 'Temporarily nullable for Phase 1 testing. Will be made NOT NULL in Phase 2.'"
  end
end
