module Boolean; end

class String
  TRUTHY = (/^(true|t|yes|y|1)$/i)
  FALSY = (/^(false|f|no|n|0)$/i)

  def to_b
    return true if self =~ TRUTHY
    return false if self.blank? || self =~ FALSY
    raise ArgumentError.new("invalid value for Boolean: '#{self}'")
  end

  def to_b?
    self =~ TRUTHY || self.blank? || self =~ FALSY
  end
end

class Numeric
  def to_b
    return true if self == 1
    return false if self == 0
    raise ArgumentError.new("invalid value for Boolean: '#{self}'")
  end

  def to_b?
    self == 1 || self == 0
  end
end

class TrueClass
  include Boolean
  def to_b; self; end
  def to_b?; true; end
end

class FalseClass
  include Boolean
  def to_b; self; end
  def to_b?; true; end
end

class NilClass
  def to_b; false; end
  def to_b?; true; end
end
