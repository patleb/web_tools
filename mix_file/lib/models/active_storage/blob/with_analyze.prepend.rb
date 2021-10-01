module ActiveStorage::Blob::WithAnalyze
  def analyze
    with_lock do
      super
    end
  end
end
