class Hash
  REPLACE = '!'.freeze
  KEYWORD = /^[a-z_]\w*$/i.freeze

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

  def pretty_hash!(default = nil)
    return default unless present?
    pretty_hash
  end

  def pretty_hash
    sort_by{ |k, _| k.to_s }.to_h.cast.to_s.gsub(/:(\w+)=>/, '\1: ')
  end

  def cast!
    deep_transform_keys!{ |key| _cast_key(key) }.deep_transform_values!{ |value| _cast_value(value) }
  end

  def cast
    deep_transform_keys{ |key| _cast_key(key) }.deep_transform_values{ |value| _cast_value(value) }
  end

  private

  def _cast_key(key)
    if key.is_a? String
      case
      when key.to_i?           then key.to_i
      when key.match?(KEYWORD) then key.to_sym
      else key
      end
    else
      key
    end
  end

  def _cast_value(value)
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
