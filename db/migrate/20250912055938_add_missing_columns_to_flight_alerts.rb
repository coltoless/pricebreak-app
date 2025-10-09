class AddMissingColumnsToFlightAlerts < ActiveRecord::Migration[8.0]
  def change
    add_column :flight_alerts, :alert_status, :string
    add_column :flight_alerts, :price_drop_amount, :decimal
  end
end
