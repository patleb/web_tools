class ActiveStorage::OptimizeJob < ActiveStorage::BaseJob
  discard_on ActiveRecord::RecordNotFound
  retry_on ActiveStorage::IntegrityError, attempts: 10, wait: :exponentially_longer

  def perform(blob)
    blob.optimize
  end
end
