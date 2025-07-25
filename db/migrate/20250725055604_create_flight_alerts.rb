class CreateFlightAlerts < ActiveRecord::Migration[8.0]
  def change
    create_table :flight_alerts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :origin, null: false
      t.string :destination, null: false
      t.date :departure_date, null: false
      t.date :return_date
      t.integer :passengers, default: 1
      t.string :cabin_class, default: 'economy'
      t.decimal :price_min, precision: 10, scale: 2
      t.decimal :price_max, precision: 10, scale: 2
      t.decimal :target_price, precision: 10, scale: 2, null: false
      t.string :notification_method, default: 'email'
      t.boolean :wedding_mode, default: false
      t.date :wedding_date
      t.integer :guest_count, default: 1
      t.string :status, default: 'active'
      t.jsonb :auto_buy_settings, default: {}

      t.timestamps
    end

    add_index :flight_alerts, :status
    add_index :flight_alerts, :wedding_mode
    add_index :flight_alerts, :departure_date
    add_index :flight_alerts, [:origin, :destination]
    add_index :flight_alerts, :auto_buy_settings, using: :gin
  end
end
