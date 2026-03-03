class AddSummaryToListings < ActiveRecord::Migration[7.2]
  def change
    add_column :listings, :summary, :text
  end
end
