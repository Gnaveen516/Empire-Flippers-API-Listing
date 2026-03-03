require 'rails_helper'
require 'webmock/rspec'

RSpec.describe EfSyncService do
  describe '.sync' do
    let(:api_response_page1) do
      {
        data: {
          listings: [
            {
              'listing_number' => '12345',
              'listing_price' => 100000,
              'listing_status' => 'For Sale',
              'summary' => 'Great e-commerce business'
            },
            {
              'listing_number' => '67890',
              'listing_price' => 200000,
              'listing_status' => 'For Sale',
              'summary' => 'Profitable SaaS product'
            }
          ]
        }
      }.to_json
    end

    let(:api_response_page2) do
      {
        data: {
          listings: [
            {
              'listing_number' => '11111',
              'listing_price' => 150000,
              'listing_status' => 'For Sale',
              'summary' => 'Content website'
            }
          ]
        }
      }.to_json
    end

    let(:api_response_empty) do
      {
        data: {
          listings: []
        }
      }.to_json
    end

    let(:hubspot_create_response) do
      { id: '123456', properties: { dealname: 'Listing #12345' } }.to_json
    end

    before do
      stub_request(:get, 'https://api.empireflippers.com/api/v1/listings/list?page=1&listing_status=For%20Sale')
        .to_return(status: 200, body: api_response_page1, headers: { 'Content-Type' => 'application/json' })

      stub_request(:get, 'https://api.empireflippers.com/api/v1/listings/list?page=2&listing_status=For%20Sale')
        .to_return(status: 200, body: api_response_page2, headers: { 'Content-Type' => 'application/json' })

      stub_request(:get, 'https://api.empireflippers.com/api/v1/listings/list?page=3&listing_status=For%20Sale')
        .to_return(status: 200, body: api_response_empty, headers: { 'Content-Type' => 'application/json' })

      stub_request(:post, 'https://api.hubapi.com/crm/v3/objects/deals')
        .to_return(status: 200, body: hubspot_create_response, headers: { 'Content-Type' => 'application/json' })

      ENV['HUBSPOT_ACCESS_TOKEN'] = 'test_token'
    end

    after do
      ENV.delete('HUBSPOT_ACCESS_TOKEN')
    end

    it 'fetches all pages of listings and saves them to the database' do
      expect { described_class.sync }.to change { Listing.count }.by(3)

      listing1 = Listing.find_by(listing_number: '12345')
      expect(listing1.price).to eq(100000)
      expect(listing1.status).to eq('For Sale')
      expect(listing1.summary).to eq('Great e-commerce business')

      listing2 = Listing.find_by(listing_number: '67890')
      expect(listing2.price).to eq(200000)
      expect(listing2.summary).to eq('Profitable SaaS product')

      listing3 = Listing.find_by(listing_number: '11111')
      expect(listing3.price).to eq(150000)
      expect(listing3.summary).to eq('Content website')
    end

    it 'creates Hubspot deals with all required properties' do
      described_class.sync

      expect(WebMock).to have_requested(:post, 'https://api.hubapi.com/crm/v3/objects/deals').times(3)
      
      listing = Listing.find_by(listing_number: '12345')
      expect(listing.hubspot_deal_id).to eq('123456')
    end

    it 'includes closedate 30 days from now in deal properties' do
      described_class.sync

      expect(WebMock).to have_requested(:post, 'https://api.hubapi.com/crm/v3/objects/deals').times(3)
      
      # Verify at least one request has closedate
      expect(a_request(:post, 'https://api.hubapi.com/crm/v3/objects/deals')
        .with { |req|
          body = JSON.parse(req.body)
          properties = body['properties']
          properties['closedate'].is_a?(Integer) && properties['closedate'] > Time.now.to_i * 1000
        }).to have_been_made.at_least_once
    end

    it 'includes description from summary in deal properties' do
      described_class.sync

      expect(a_request(:post, 'https://api.hubapi.com/crm/v3/objects/deals')
        .with { |req|
          body = JSON.parse(req.body)
          properties = body['properties']
          properties['description'] == 'Great e-commerce business'
        }).to have_been_made.once
    end

    context 'when listing already has hubspot_deal_id' do
      before do
        Listing.create!(
          listing_number: '12345',
          price: 100000,
          status: 'For Sale',
          summary: 'Great e-commerce business',
          hubspot_deal_id: 'existing_deal_123'
        )
      end

      it 'does not create duplicate deals' do
        expect { described_class.sync }.to change { Listing.count }.by(2)
        
        expect(WebMock).to have_requested(:post, 'https://api.hubapi.com/crm/v3/objects/deals').times(2)
      end
    end

    context 'when listing already exists in database' do
      before do
        Listing.create!(listing_number: '12345', price: 50000, status: 'For Sale', summary: 'Old summary')
      end

      it 'does not create duplicate listings' do
        expect { described_class.sync }.to change { Listing.count }.by(2)
        
        listing = Listing.find_by(listing_number: '12345')
        expect(listing.price).to eq(50000)
        expect(listing.summary).to eq('Old summary')
      end
    end

    context 'when HUBSPOT_ACCESS_TOKEN is not set' do
      before do
        ENV.delete('HUBSPOT_ACCESS_TOKEN')
      end

      it 'saves listings but skips Hubspot integration' do
        expect { described_class.sync }.to change { Listing.count }.by(3)
        expect(WebMock).not_to have_requested(:post, 'https://api.hubapi.com/crm/v3/objects/deals')
      end
    end
  end
end
