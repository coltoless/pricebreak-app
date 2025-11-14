class AddPreferencesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :email_subscription, :boolean, default: false
    add_column :users, :preferred_airports, :jsonb, default: []
  end
end
