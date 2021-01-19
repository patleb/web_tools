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

class Numeric
  B_PER_MB = BigDecimal(1_048_576).freeze
  B_PER_GB = BigDecimal(1_073_741_824).freeze
  KB_PER_MB = BigDecimal(1_024).freeze
  KB_PER_GB = BigDecimal(1_048_576).freeze

  def bytes_to_mb
    self / B_PER_MB
  end

  def bytes_to_gb
    self / B_PER_GB
  end

  def kbytes_to_mb
    self / KB_PER_MB
  end

  def kbytes_to_gb
    self / KB_PER_GB
  end
end
