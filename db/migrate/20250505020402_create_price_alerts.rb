class CreatePriceAlerts < ActiveRecord::Migration[7.0]
  def change
    create_table :price_alerts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :query
      t.string :category, array: true, default: []
      t.string :venue_type, array: true, default: []
      t.string :artist
      t.string :team
      t.string :from
      t.string :to
      t.decimal :price_min, precision: 10, scale: 2
      t.decimal :price_max, precision: 10, scale: 2
      t.decimal :target_price, precision: 10, scale: 2, null: false
      t.string :notification_method, null: false
      t.string :status, null: false, default: 'active'
      t.datetime :triggered_at

      t.timestamps
    end

    add_index :price_alerts, :status
    add_index :price_alerts, [:user_id, :status]
  end
end 