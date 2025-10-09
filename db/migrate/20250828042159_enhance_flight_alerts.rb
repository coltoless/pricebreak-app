class EnhanceFlightAlerts < ActiveRecord::Migration[8.0]
  def change
    # Temporarily comment out for Phase 1 testing
    # add_reference :flight_alerts, :flight_filter, null: true, foreign_key: true
    add_column :flight_alerts, :current_price, :decimal, precision: 10, scale: 2
    add_column :flight_alerts, :price_drop_percentage, :decimal, precision: 5, scale: 2
    add_column :flight_alerts, :alert_triggers, :jsonb, default: {}
    add_column :flight_alerts, :notification_history, :jsonb, default: {}
    add_column :flight_alerts, :booking_actions, :jsonb, default: {}
    add_column :flight_alerts, :next_check_scheduled, :datetime
    add_column :flight_alerts, :alert_quality_score, :decimal, precision: 3, scale: 2, default: 1.0
    
    # Add indexes for performance (flight_filter_id is automatically indexed by references)
    add_index :flight_alerts, :current_price
    add_index :flight_alerts, :next_check_scheduled
    add_index :flight_alerts, :alert_triggers, using: :gin
    add_index :flight_alerts, :notification_history, using: :gin
    add_index :flight_alerts, :booking_actions, using: :gin
  end
end
