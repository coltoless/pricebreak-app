class AddLastCheckedToFlightAlerts < ActiveRecord::Migration[8.0]
  def change
    add_column :flight_alerts, :last_checked, :datetime
  end
end
