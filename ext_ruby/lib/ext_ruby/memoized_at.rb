# TODO add possibility to have several thresholds defined by conditions
module MemoizedAt
  ACCESS_THRESHOLD = 5.0

  def m_access(name, *constants, threshold: ACCESS_THRESHOLD, touch: false)
    @m_access_at ||= {}
    @m_access_cache ||= {}
    access_key = m_access_key(name, constants)
    if !@m_access_cache.has_key?(access_key) || (Time.now - @m_access_at[access_key]) > threshold
      value = @m_access_cache[access_key] = block_given? ? yield : send(name, *constants)
      @m_access_at[access_key] = Time.now
    else
      value = @m_access_cache[access_key]
      @m_access_at[access_key] = Time.now if touch
    end
    value
  end

  def m_clear(name = nil, *constants)
    if name.nil?
      @m_access_at = {}
      @m_access_cache = {}
    else
      @m_access_at ||= {}
      @m_access_cache ||= {}
      access_key = m_access_key(name, constants)
      @m_access_at.delete(access_key)
      @m_access_cache.delete(access_key)
    end
  end

  private

  def m_access_key(name, constants)
    constants = constants.compact
    constants.any? ? "#{name}:#{constants.map(&:to_s).join(':')}" : name.to_s
  end
end
