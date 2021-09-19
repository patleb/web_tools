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
