# frozen_string_literal: true

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

class NilClass
  def simplify(*)
  end
end

class Numeric
  B_PER_KB = BigDecimal(1_024)
  B_PER_MB = BigDecimal(1_048_576)
  B_PER_GB = BigDecimal(1_073_741_824)
  KB_PER_MB = BigDecimal(1_024)
  KB_PER_GB = BigDecimal(1_048_576)
  MB_PER_GB = BigDecimal(1_024)

  def simplify(n = 5)
    sign, significant_digits, base, exponent = to_d.split
    raise 'must be for numbers with base 10' if base != 10
    upper, lower = significant_digits.split('9' * n, 2)
    if lower.nil?
      upper, lower = significant_digits.split('0' * n, 2)
      unless lower.nil?
        significant_digits = upper.to_i
      end
    elsif upper.empty?
      significant_digits = '1'
      exponent += 1
    else
      significant_digits = (upper.to_i + 1).to_s
    end
    result = sign * "0.#{significant_digits}".to_f * (base ** exponent)
    result.floor(-exponent + significant_digits.size)
  end

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
