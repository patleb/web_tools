class TrueClass
  def to_i; 1; end
  def to_f; 1.0; end
  def to_d; BigDecimal(1) end
end

class FalseClass
  def to_i; 0; end
  def to_f; 0.0; end
  def to_d; BigDecimal(0) end
end

class NilClass
  def to_d; BigDecimal(0) end
end

class Object
  def to_i?; false end
  def to_f?; false end
  def to_d?; false end
end

class String
  def to_i?; to_i.to_s == self end
  def to_f?; to_f.to_s == self end
  def to_d?; to_d.to_s == self end
end

class Integer
  def to_i?; true end
  def to_f?; to_f == self end
  def to_d?; to_d == self end
end

class Float
  def to_i?; to_i == self end
  def to_f?; true end
  def to_d?; to_d == self end
end

class BigDecimal
  def to_i?; to_i == self end
  def to_f?; to_f == self end
  def to_d?; true end
end
