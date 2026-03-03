require 'sidekiq'
require 'sidekiq-scheduler'

Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0') }
end

# Set the schedule directly
Sidekiq.schedule = {
  'sync_listings_daily' => {
    'cron' => '0 0 * * *',  # Run daily at midnight
    'class' => 'SyncListingsJob',
    'queue' => 'default'
  }
}
