module Boolean; end

class String
  def to_b
    return true if self == true || self =~ (/^(true|t|yes|y|1)$/i)
    return false if self == false || self.blank? || self =~ (/^(false|f|no|n|0)$/i)
    raise ArgumentError.new("invalid value for Boolean: '#{self}'")
  end

  def to_b?
    self == true || self =~ (/^(true|t|yes|y|1)$/i) || self == false || self.blank? || self =~ (/^(false|f|no|n|0)$/i)
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
  alias_method :to_str, :to_s
end

class FalseClass
  include Boolean
  def to_b; self; end
  def to_b?; true; end
  alias_method :to_str, :to_s
end

class NilClass
  def to_b; false; end
  def to_b?; true; end
end
