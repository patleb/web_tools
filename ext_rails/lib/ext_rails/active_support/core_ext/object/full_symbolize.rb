class Object
  def full_symbolize
    self
  end
end

class Array
  def full_symbolize
    self.each_with_object([]) do |val, res|
      res << case val
        when Hash, Array then val.full_symbolize
        when String      then val.to_sym
        else val
      end
    end
  end
end

class Hash
  def full_symbolize
    self.each_with_object({}) do |(key, val), res|
      nkey = key.is_a?(String) ? key.to_sym : key
      nval = case val
        when Hash, Array then val.full_symbolize
        when String      then val.to_sym
        else val
        end
      res[nkey] = nval
    end
  end
end
