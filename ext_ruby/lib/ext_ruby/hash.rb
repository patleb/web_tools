class Hash
  def self.union(_key, old_value, new_value)
    if old_value.is_a?(Array) && new_value.is_a?(Array)
      old_value | new_value
    elsif old_value.is_a?(Hash) && new_value.is_a?(Hash)
      old_value.merge(new_value)
    else
      new_value
    end
  end

  def union!(*hashes, &block)
    if block_given?
      merge!(*hashes, &block)
    else
      merge!(*hashes, &self.class.method(:union))
    end
  end

  def union(*hashes, &block)
    if block_given?
      merge(*hashes, &block)
    else
      merge(*hashes, &self.class.method(:union))
    end
  end
end
