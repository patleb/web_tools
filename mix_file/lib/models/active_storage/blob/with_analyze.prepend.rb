MonkeyPatch.add{['activestorage', 'app/models/active_storage/blob/analyzable.rb', 'd96f3eac18b413d12c146584d40fae6b7a8c8a322d5e86e86bb914a64ecce2a5']}

module ActiveStorage::Blob::WithAnalyze
  def analyze
    with_lock do
      super
    end
  end
end
