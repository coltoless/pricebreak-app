class AddExtendedPreferencesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :home_city, :string
    add_column :users, :currency, :string, default: 'USD'
    add_column :users, :language, :string, default: 'en'
    add_column :users, :timezone, :string, default: 'UTC'
  end
end
