class CreateFlightProviderData < ActiveRecord::Migration[8.0]
  def change
    create_table :flight_provider_data do |t|
      t.string :flight_identifier, null: false
      t.string :provider, null: false
      t.string :route, null: false
      t.jsonb :schedule, null: false, default: {}
      t.jsonb :pricing, null: false, default: {}
      t.datetime :data_timestamp, null: false
      t.string :validation_status, default: 'pending'
      t.string :duplicate_group_id

      t.timestamps
    end

    # Add indexes for performance
    add_index :flight_provider_data, :flight_identifier
    add_index :flight_provider_data, :provider
    add_index :flight_provider_data, :route
    add_index :flight_provider_data, :data_timestamp
    add_index :flight_provider_data, :validation_status
    add_index :flight_provider_data, :duplicate_group_id
    add_index :flight_provider_data, :schedule, using: :gin
    add_index :flight_provider_data, :pricing, using: :gin
    add_index :flight_provider_data, [:flight_identifier, :provider], unique: true
  end
end
