MonkeyPatch.add{['activestorage', 'app/models/active_storage/attachment.rb', 'f3ad4d9127b926fcc6b5ac8007075091fdd3e492e9bafc21163404bdcd62b3aa']}

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
