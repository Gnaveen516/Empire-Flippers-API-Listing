class AddHubspotDealIdToListings < ActiveRecord::Migration[7.2]
  def change
    add_column :listings, :hubspot_deal_id, :string
  end
end
