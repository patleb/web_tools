module ActiveSupport::Dependencies::ClassCache::WithNilableCache
  def safe_get(key)
    key = key.name if key.respond_to?(:name)
    if @store.key? key
      @store[key]
    else
      @store[key] = super
    end
  end
end

ActiveSupport::Dependencies::ClassCache.prepend ActiveSupport::Dependencies::ClassCache::WithNilableCache
