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

  def pretty_hash!
    pretty_hash.presence
  end

  def pretty_hash
    sort_by(&:first).to_h
      .deep_transform_keys{ |key| _pretty_hash_key(key) }
      .deep_transform_values{ |value| _pretty_hash_value(value) }
      .to_s
      .gsub(/:(\w+)=>/, '\1: ')
  end

  private

  def _pretty_hash_key(key)
    if key.is_a? String
      case
      when key.to_i?                    then key.to_i
      when key.match?(/^\w+$/)          then key.to_sym
      else key
      end
    else
      key
    end
  end

  def _pretty_hash_value(value)
    if value.is_a? String
      case
      when value.to_f?                    then value.to_f
      when value.to_i?                    then value.to_i
      when value.match?(/^(true|false)$/) then value.to_b
      else value
      end
    else
      value
    end
  end
end
