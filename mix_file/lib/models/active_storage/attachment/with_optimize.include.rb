MonkeyPatch.add{['activestorage', 'app/models/active_storage/attachment.rb', '06f3db38d14ef796eef38568964a97dcfdeeb9b19cf569ba73e22c93025f9d38']}

module ActiveStorage::Attachment::WithOptimize
  extend ActiveSupport::Concern

  included do
    after_create_commit :optimize_blob_later
  end

  private

  def optimize_blob_later
    blob.optimize_later if blob.optimizable?
  end
end
