class SyncListingsJob < ApplicationJob
  queue_as :default

  def perform
    EfSyncService.sync
  end
end
