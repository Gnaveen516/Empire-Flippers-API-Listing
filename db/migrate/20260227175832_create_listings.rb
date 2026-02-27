class CreateListings < ActiveRecord::Migration[7.2]
  def change
    create_table :listings do |t|
      t.string :listing_number
      t.integer :price
      t.string :status

      t.timestamps
    end
  end
end
