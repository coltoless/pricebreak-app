class AddPriceRangeToPriceAlerts < ActiveRecord::Migration[7.1]
  def change
    add_column :price_alerts, :min_price, :decimal, precision: 10, scale: 2
    add_column :price_alerts, :max_price, :decimal, precision: 10, scale: 2
  end
end 