class EfSyncService
  def self.sync
    all_listings = fetch_all_listings
    puts "Total listings fetched: #{all_listings.count}"
    return unless all_listings.any?
    
    all_listings.each do |listing_data|
      listing = save_listing(listing_data)
      create_hubspot_deal(listing) if listing_data['listing_status'] == 'For Sale'
    end
  end

  private

  def self.fetch_all_listings
    all_listings = []
    page = 1
    
    loop do
      response = HTTParty.get("https://api.empireflippers.com/api/v1/listings/list?page=#{page}&listing_status=For%20Sale")
      puts "Fetching page #{page}, Response code: #{response.code}"
      
      data = response.parsed_response
      listings = data.dig('data', 'listings') || []
      
      break if listings.empty?
      
      all_listings.concat(listings)
      page += 1
    end
    
    all_listings
  end

  def self.save_listing(data)
    Listing.find_or_create_by(listing_number: data['listing_number']) do |listing|
      listing.price = data['listing_price']
      listing.status = data['listing_status']
      listing.summary = data['summary']
    end
  end

  def self.create_hubspot_deal(listing)
    return unless ENV['HUBSPOT_ACCESS_TOKEN'].present?
    return if listing.hubspot_deal_id.present?
    
    client = Hubspot::Client.new(access_token: ENV['HUBSPOT_ACCESS_TOKEN'])
    deal_name = "Listing ##{listing.listing_number}"
    close_date = (Time.now + 30.days).to_date.to_time.to_i * 1000

    deal = client.crm.deals.basic_api.create(
      simple_public_object_input_for_create: {
        properties: {
          dealname: deal_name,
          amount: listing.price,
          closedate: close_date,
          description: listing.summary
        }
      }
    )
    
    listing.update(hubspot_deal_id: deal.id)
  end
end
