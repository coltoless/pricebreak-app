class CreateFlightFilters < ActiveRecord::Migration[8.0]
  def change
    create_table :flight_filters do |t|
      # Temporarily comment out for Phase 1 testing
      # t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.text :origin_airports, null: false
      t.text :destination_airports, null: false
      t.string :trip_type, null: false, default: 'round-trip'
      t.text :departure_dates, null: false
      t.text :return_dates
      t.boolean :flexible_dates, default: false
      t.integer :date_flexibility, default: 3
      t.jsonb :passenger_details, null: false, default: {}
      t.jsonb :price_parameters, null: false, default: {}
      t.jsonb :advanced_preferences, null: false, default: {}
      t.jsonb :alert_settings, null: false, default: {}
      t.boolean :is_active, default: true

      t.timestamps
    end

    # Add indexes for performance (user_id is automatically indexed by references)
    add_index :flight_filters, :is_active
    add_index :flight_filters, :trip_type
    add_index :flight_filters, :passenger_details, using: :gin
    add_index :flight_filters, :price_parameters, using: :gin
    add_index :flight_filters, :advanced_preferences, using: :gin
    add_index :flight_filters, :alert_settings, using: :gin
  end
end
