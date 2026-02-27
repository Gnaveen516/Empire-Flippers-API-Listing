require 'rails_helper'
require 'webmock/rspec'

RSpec.describe EfSyncService do
  describe '.sync' do
    let(:api_response) do
      {
        data: {
          listings: [
            {
              'listing_number' => '12345',
              'price' => 100000,
              'listing_status' => 'For Sale'
            },
            {
              'listing_number' => '67890',
              'price' => 200000,
              'listing_status' => 'For Sale'
            }
          ]
        }
      }.to_json
    end

    let(:hubspot_search_response) do
      { results: [] }.to_json
    end

    let(:hubspot_create_response) do
      { id: '123', properties: { dealname: 'Listing #12345' } }.to_json
    end

    before do
      stub_request(:get, 'https://api.empireflippers.com/api/v1/listings/list?page=1&listing_status=For%20Sale')
        .to_return(status: 200, body: api_response, headers: { 'Content-Type' => 'application/json' })

      stub_request(:post, 'https://api.hubapi.com/crm/v3/objects/deals/search')
        .to_return(status: 200, body: hubspot_search_response, headers: { 'Content-Type' => 'application/json' })

      stub_request(:post, 'https://api.hubapi.com/crm/v3/objects/deals')
        .to_return(status: 200, body: hubspot_create_response, headers: { 'Content-Type' => 'application/json' })

      ENV['HUBSPOT_ACCESS_TOKEN'] = 'test_token'
    end

    after do
      ENV.delete('HUBSPOT_ACCESS_TOKEN')
    end

    it 'fetches listings and saves them to the database' do
      expect { described_class.sync }.to change { Listing.count }.by(2)

      listing1 = Listing.find_by(listing_number: '12345')
      expect(listing1.price).to eq(100000)
      expect(listing1.status).to eq('For Sale')

      listing2 = Listing.find_by(listing_number: '67890')
      expect(listing2.price).to eq(200000)
    end

    it 'creates Hubspot deals for For Sale listings' do
      described_class.sync

      expect(WebMock).to have_requested(:post, 'https://api.hubapi.com/crm/v3/objects/deals/search').twice
      expect(WebMock).to have_requested(:post, 'https://api.hubapi.com/crm/v3/objects/deals').twice
    end

    context 'when deal already exists in Hubspot' do
      let(:hubspot_search_response_with_results) do
        { results: [{ id: '999', properties: { dealname: 'Listing #12345' } }] }.to_json
      end

      before do
        stub_request(:post, 'https://api.hubapi.com/crm/v3/objects/deals/search')
          .to_return(status: 200, body: hubspot_search_response_with_results, headers: { 'Content-Type' => 'application/json' })
      end

      it 'does not create duplicate deals' do
        described_class.sync

        expect(WebMock).to have_requested(:post, 'https://api.hubapi.com/crm/v3/objects/deals/search').twice
        expect(WebMock).not_to have_requested(:post, 'https://api.hubapi.com/crm/v3/objects/deals')
      end
    end

    context 'when listing already exists in database' do
      before do
        Listing.create!(listing_number: '12345', price: 50000, status: 'For Sale')
      end

      it 'does not create duplicate listings' do
        expect { described_class.sync }.to change { Listing.count }.by(1)
        
        listing = Listing.find_by(listing_number: '12345')
        expect(listing.price).to eq(50000) # Should not update existing
      end
    end

    context 'when HUBSPOT_ACCESS_TOKEN is not set' do
      before do
        ENV.delete('HUBSPOT_ACCESS_TOKEN')
      end

      it 'saves listings but skips Hubspot integration' do
        expect { described_class.sync }.to change { Listing.count }.by(2)
        expect(WebMock).not_to have_requested(:post, 'https://api.hubapi.com/crm/v3/objects/deals/search')
      end
    end
  end
end
