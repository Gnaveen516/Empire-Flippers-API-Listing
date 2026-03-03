# Empire Flippers Challenge

A Rails API application that syncs listings from Empire Flippers API to a local PostgreSQL database and creates corresponding deals in HubSpot CRM.

## Features

- Fetches ALL listings from Empire Flippers API (with pagination)
- Stores listings locally in PostgreSQL with summary field
- Creates HubSpot deals for "For Sale" listings with:
  - Deal Name: "Listing #[listing_number]"
  - Amount: listing price
  - Close Date: 30 days from current time
  - Description: listing summary
- Prevents duplicate deals using database-based tracking (hubspot_deal_id)
- Prevents duplicate listings in database
- Automated daily sync using Sidekiq Scheduler
- Full test coverage with RSpec and WebMock

## Tech Stack

- Ruby 3.3.6
- Rails 7.2
- PostgreSQL
- Redis (for Sidekiq)
- HTTParty (API requests)
- HubSpot API Client
- Sidekiq + Sidekiq-Scheduler (background jobs & scheduling)
- RSpec + WebMock (testing)

## Setup Instructions

### Prerequisites

- Ruby 3.3.6
- PostgreSQL
- Redis (for Sidekiq)
- Bundler

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd ef_challenge
```

2. Install dependencies:
```bash
bundle install
```

3. Create and setup the database:
```bash
rails db:create
rails db:migrate
```

4. Create `.env` file in the root directory:
```bash
HUBSPOT_ACCESS_TOKEN=your_hubspot_token_here
```

**Note:** HubSpot integration is optional. The app will work without the token but won't create deals.

### Getting HubSpot Access Token (Optional)

1. Go to https://developers.hubspot.com/
2. Create a free account or sign in
3. Create a new app or use Private Apps (Settings → Integrations → Private Apps)
4. Add scopes: `crm.objects.deals.read` and `crm.objects.deals.write`
5. Copy the access token to your `.env` file

## Running the Application

### Start Redis (Required for Sidekiq)

```bash
# macOS
brew services start redis

# Linux
sudo service redis-server start

# Or run in foreground
redis-server
```

### Start Sidekiq (For Daily Scheduled Sync)

In a separate terminal:

```bash
bundle exec sidekiq
```

Sidekiq will automatically run the sync job daily at midnight (configured in `config/sidekiq.yml`).

### Manual Sync (Optional)

Run the sync service from Rails console:

```bash
rails console
```

Then execute:

```ruby
EfSyncService.sync
```

Or run directly from command line:

```bash
rails runner "EfSyncService.sync"
```

### Check Stored Data

In Rails console:

```ruby
# View all listings
Listing.all

# Count listings
Listing.count

# Find specific listing
Listing.find_by(listing_number: '91646')
```

## Running Tests

Run the full test suite:

```bash
bundle exec rspec
```

Run specific test file:

```bash
bundle exec rspec spec/services/ef_sync_service_spec.rb
```

## Project Structure

```
app/
├── jobs/
│   └── sync_listings_job.rb    # Daily scheduled job
├── models/
│   └── listing.rb              # Listing model
└── services/
    └── ef_sync_service.rb      # Main sync service

config/
├── initializers/
│   └── sidekiq.rb              # Sidekiq configuration
└── sidekiq.yml                 # Sidekiq scheduler config

spec/
├── jobs/
│   └── sync_listings_job_spec.rb  # Job tests
└── services/
    └── ef_sync_service_spec.rb    # Service tests

db/
└── migrate/
    ├── [timestamp]_create_listings.rb
    ├── [timestamp]_add_summary_to_listings.rb
    └── [timestamp]_add_hubspot_deal_id_to_listings.rb
```

## API Endpoints Used

- **Empire Flippers API:** `https://api.empireflippers.com/api/v1/listings/list`
- **HubSpot CRM API:** `https://api.hubapi.com/crm/v3/objects/deals`

## How It Works

1. Sidekiq Scheduler runs `SyncListingsJob` daily at midnight
2. Job calls `EfSyncService.sync` which:
   - Fetches ALL pages of listings from Empire Flippers API (pagination loop)
   - Saves each listing to the local database with summary
   - For "For Sale" listings without a `hubspot_deal_id`:
     - Creates a new HubSpot deal with:
       - Deal Name: "Listing #[listing_number]"
       - Amount: listing price
       - Close Date: 30 days from now
       - Description: listing summary
     - Stores the HubSpot deal ID in the database
   - Skips deal creation if listing already has a `hubspot_deal_id` (prevents duplicates)

## Database Schema

**Listings Table:**
- `listing_number` (string) - Unique identifier
- `price` (integer) - Listing price
- `status` (string) - Listing status (e.g., "For Sale")
- `summary` (text) - Listing description/summary
- `hubspot_deal_id` (string) - HubSpot deal ID for duplicate prevention
- `created_at` (datetime)
- `updated_at` (datetime)

## Testing

Tests use WebMock to stub external API calls, ensuring:
- Fast test execution
- No real API calls during testing
- Predictable test results

Test coverage includes:
- ✅ Fetching all pages of listings (pagination)
- ✅ Saving listings with summary field
- ✅ Creating HubSpot deals with all required properties
- ✅ Close date set to 30 days from now
- ✅ Description populated from summary
- ✅ Preventing duplicate deals using database tracking
- ✅ Preventing duplicate listings
- ✅ Handling missing HubSpot token
- ✅ Daily sync job execution

## Troubleshooting

### Ruby Version Issues

If you encounter syntax errors, ensure you're using Ruby 3.3.6:

```bash
ruby -v
```

If using rbenv:

```bash
rbenv install 3.3.6
rbenv local 3.3.6
```

### Database Connection Issues

Ensure PostgreSQL is running:

```bash
# macOS
brew services start postgresql

# Linux
sudo service postgresql start
```

### HubSpot API Errors

If you see 401 errors, your token may be expired. Generate a new token from HubSpot.

## License

MIT
