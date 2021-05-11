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
  B_PER_KB = BigDecimal(1_024).freeze
  B_PER_MB = BigDecimal(1_048_576).freeze
  B_PER_GB = BigDecimal(1_073_741_824).freeze
  KB_PER_MB = BigDecimal(1_024).freeze
  KB_PER_GB = BigDecimal(1_048_576).freeze
  MB_PER_GB = BigDecimal(1_024).freeze

  def sign
    self <=> 0
  end

  def kb_to_bytes
    (self * B_PER_KB).to_i
  end

  def mb_to_bytes
    (self * B_PER_MB).to_i
  end

  def gb_to_bytes
    (self * B_PER_GB).to_i
  end

  def bytes_to_kb(precision = 3)
    precision ? (self / B_PER_KB).to_f.ceil(precision) : (self / B_PER_KB).ceil
  end

  def bytes_to_mb(precision = 3)
    precision ? (self / B_PER_MB).to_f.ceil(precision) : (self / B_PER_MB).ceil
  end

  def bytes_to_gb(precision = 3)
    precision ? (self / B_PER_GB).to_f.ceil(precision) : (self / B_PER_GB).ceil
  end

  def kb_to_mb(precision = 3)
    precision ? (self / KB_PER_MB).to_f.ceil(precision) : (self / KB_PER_MB).ceil
  end

  def kb_to_gb(precision = 3)
    precision ? (self / KB_PER_GB).to_f.ceil(precision) : (self / KB_PER_GB).ceil
  end

  def mb_to_gb(precision = 3)
    precision ? (self / MB_PER_GB).to_f.ceil(precision) : (self / MB_PER_GB).ceil
  end

  def to_hours
    mm, ss = self.divmod(60)
    ss = ss.ceil
    hh, mm = mm.divmod(60)
    [hh, mm, ss]
  end

  def to_days
    hh, mm, ss = to_hours
    dd, hh = hh.divmod(24)
    [dd, hh, mm, ss]
  end
end
