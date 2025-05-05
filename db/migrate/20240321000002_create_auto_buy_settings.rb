class CreateAutoBuySettings < ActiveRecord::Migration[7.1]
  def change
    create_table :auto_buy_settings do |t|
      t.references :price_alert, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :enabled, default: false
      t.integer :max_attempts, default: 3
      t.integer :attempts_count, default: 0
      t.string :payment_method_type
      t.string :payment_method_id
      t.text :billing_address

      t.timestamps
    end

    add_index :auto_buy_settings, [:price_alert_id, :user_id], unique: true
  end
end 