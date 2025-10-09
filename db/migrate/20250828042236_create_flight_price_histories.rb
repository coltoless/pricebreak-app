class CreateFlightPriceHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :flight_price_histories do |t|
      t.string :route, null: false
      t.date :date, null: false
      t.string :provider, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.string :booking_class, null: false
      t.datetime :timestamp, null: false
      t.decimal :data_quality_score, precision: 3, scale: 2, default: 1.0
      t.string :price_validation_status, default: 'valid'

      t.timestamps
    end

    # Add indexes for performance
    add_index :flight_price_histories, :route
    add_index :flight_price_histories, :date
    add_index :flight_price_histories, :provider
    add_index :flight_price_histories, :price
    add_index :flight_price_histories, :timestamp
    add_index :flight_price_histories, :data_quality_score
    add_index :flight_price_histories, :price_validation_status
    add_index :flight_price_histories, [:route, :date, :provider], unique: true
  end
end
