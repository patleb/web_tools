class Hash
  REPLACE = '!'.freeze

  def self.union(key, old_value, new_value)
    if key.to_s.end_with? REPLACE
      new_value
    elsif old_value.is_a?(Array) && new_value.is_a?(Array)
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

  def pretty_json
    JSON.pretty_generate(self, indent: '  ', space: ' ', space_before: '')
  end

  def pretty_hash
    sort_by(&:first).to_h
      .deep_transform_keys{ |key| key.is_a?(String) && key.match?(/^\w+$/) ? key.to_sym : key }.to_s
      .gsub(/:(\w+)=>/, '\1: ')
  end
end
