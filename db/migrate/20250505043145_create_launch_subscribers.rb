class CreateLaunchSubscribers < ActiveRecord::Migration[8.0]
  def change
    create_table :launch_subscribers do |t|
      t.string :email

      t.timestamps
    end
    add_index :launch_subscribers, :email, unique: true
  end
end
