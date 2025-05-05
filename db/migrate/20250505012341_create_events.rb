class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.string :name
      t.text :description
      t.string :venue
      t.string :category
      t.string :subcategory
      t.decimal :price
      t.datetime :date
      t.string :image_url
      t.string :ticket_url

      t.timestamps
    end
  end
end
