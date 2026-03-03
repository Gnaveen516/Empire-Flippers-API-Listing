require 'rails_helper'

RSpec.describe SyncListingsJob, type: :job do
  describe '#perform' do
    it 'calls EfSyncService.sync' do
      expect(EfSyncService).to receive(:sync)
      described_class.new.perform
    end
  end
end
