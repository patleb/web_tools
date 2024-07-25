module MemoizedAt
  def m_access(name, timeout: ExtRuby.config.memoized_at_timeout, force: false)
    @m_access_at ||= Concurrent::Hash.new
    @m_access_cache ||= Concurrent::Hash.new
    if force || !@m_access_cache.has_key?(name) || (Time.current - @m_access_at[name]) > timeout
      value = @m_access_cache[name] = block_given? ? yield : send(name)
      @m_access_at[name] = Time.current
    else
      value = @m_access_cache[name]
    end
    value
  end

  def m_clear(name = nil)
    if name.nil?
      @m_access_at = Concurrent::Hash.new
      @m_access_cache = Concurrent::Hash.new
    else
      @m_access_at ||= Concurrent::Hash.new
      @m_access_cache ||= Concurrent::Hash.new
      @m_access_at.delete(name)
      @m_access_cache.delete(name)
    end
  end
end
