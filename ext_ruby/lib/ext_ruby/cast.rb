class Object
  def cast
    self
  end
end

class String
  def cast
    case
    when to_f?                    then to_f
    when to_i?                    then to_i
    when match?(/^(true|false)$/) then to_b
    else self
    end
  end
end

class Array
  def cast
    map(&:cast)
  end
end

class Hash
  KEYWORD = /^[a-z_]\w*$/i.freeze

  def cast
    deep_transform_keys{ |key| _cast_key(key) }.transform_values(&:cast)
  end

  private

  def _cast_key(key)
    return key unless key.is_a? String
    case
    when key.to_i?           then key.to_i
    when key.match?(KEYWORD) then key.to_sym
    else key
    end
  end
end
