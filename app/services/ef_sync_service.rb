class EfSyncService
  def self.sync
    listings = fetch_listings
    puts "Listings: #{listings.inspect}"
    return unless listings
    
    listings.each do |listing_data|
      listing = save_listing(listing_data)
      create_hubspot_deal(listing) if listing_data['listing_status'] == 'For Sale'
    end
  end

  private

  def self.fetch_listings
    response = HTTParty.get('https://api.empireflippers.com/api/v1/listings/list?page=1&listing_status=For%20Sale')
    puts "Response code: #{response.code}"
    data = response.parsed_response
    data.dig('data', 'listings') || []
  end

  def self.save_listing(data)
    Listing.find_or_create_by(listing_number: data['listing_number']) do |listing|
      listing.price = data['price']
      listing.status = data['listing_status']
    end
  end

  def self.create_hubspot_deal(listing)
    return unless ENV['HUBSPOT_ACCESS_TOKEN'].present?
    
    client = Hubspot::Client.new(access_token: ENV['HUBSPOT_ACCESS_TOKEN'])
    deal_name = "Listing ##{listing.listing_number}"

    # Search for existing deal
    search_results = client.crm.deals.search_api.do_search(
      public_object_search_request: {
        filter_groups: [
          {
            filters: [
              {
                property_name: 'dealname',
                operator: 'EQ',
                value: deal_name
              }
            ]
          }
        ]
      }
    )
    return if search_results.results.any?

    # Create deal if it doesn't exist
    client.crm.deals.basic_api.create(
      simple_public_object_input_for_create: {
        properties: {
          dealname: deal_name,
          amount: listing.price
        }
      }
    )
  end
end
