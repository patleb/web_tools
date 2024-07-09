module Boolean
  def cast_self
    self
  end
end

class Numeric
  def cast_self
    self
  end
end

class Symbol
  def cast_self
    self
  end
end

class Time
  def cast_self
    self
  end
end

class Pathname
  def cast_self
    to_s
  end
end

class String
  def cast_self
    case
    when blank?                   then nil
    when to_f?                    then to_f
    when to_d?                    then to_d
    when to_i?                    then to_i
    when match?(/^(true|false)$/) then to_b
    else self
    end
  end
end

class Array
  def cast_self
    map{ |v| v&.cast_self }
  end
end

class Hash
  KEYWORD = /^[a-z_][a-z0-9_]*[!?]?$/i.freeze

  def cast_self
    deep_transform_keys{ |key| _cast_key(key) }.transform_values{ |v| v&.cast_self }
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
