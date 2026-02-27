# Empire Flippers Challenge

<img width="990" height="535" alt="image" src="https://github.com/user-attachments/assets/6746ad65-c020-486e-a55e-a32c44b1b076" />


A Rails API application that syncs listings from Empire Flippers API to a local PostgreSQL database and creates corresponding deals in HubSpot CRM.

## Features

- Fetches listings from Empire Flippers API
- Stores listings locally in PostgreSQL
- Creates HubSpot deals for "For Sale" listings
- Prevents duplicate deals in HubSpot
- Prevents duplicate listings in database
- Full test coverage with RSpec and WebMock

## Tech Stack

- Ruby 3.3.6
- Rails 7.2
- PostgreSQL
- HTTParty (API requests)
- HubSpot API Client
- Sidekiq (background jobs)
- RSpec + WebMock (testing)

## Setup Instructions

### Prerequisites

- Ruby 3.3.6
- PostgreSQL
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

### Sync Listings

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
├── models/
│   └── listing.rb              # Listing model
└── services/
    └── ef_sync_service.rb      # Main sync service

spec/
└── services/
    └── ef_sync_service_spec.rb # Service tests

db/
└── migrate/
    └── [timestamp]_create_listings.rb
```

## API Endpoints Used

- **Empire Flippers API:** `https://api.empireflippers.com/api/v1/listings/list`
- **HubSpot CRM API:** `https://api.hubapi.com/crm/v3/objects/deals`

## How It Works

1. `EfSyncService.sync` fetches listings from Empire Flippers API
2. Each listing is saved to the local database (or updated if exists)
3. For "For Sale" listings, the service:
   - Searches HubSpot for existing deal with name "Listing #[listing_number]"
   - Creates a new deal only if it doesn't exist
   - Skips creation if deal already exists (prevents duplicates)

## Database Schema

**Listings Table:**
- `listing_number` (string) - Unique identifier
- `price` (integer) - Listing price
- `status` (string) - Listing status (e.g., "For Sale")
- `created_at` (datetime)
- `updated_at` (datetime)

## Testing

Tests use WebMock to stub external API calls, ensuring:
- Fast test execution
- No real API calls during testing
- Predictable test results

Test coverage includes:
- ✅ Fetching and saving listings
- ✅ Creating HubSpot deals
- ✅ Preventing duplicate deals
- ✅ Preventing duplicate listings
- ✅ Handling missing HubSpot token

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
