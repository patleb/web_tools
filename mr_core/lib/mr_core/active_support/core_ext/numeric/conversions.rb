class Numeric
  B_PER_MB = BigDecimal(1_048_576).freeze
  KB_PER_MB = BigDecimal(1_024).freeze

  def bytes_to_mb
    self / B_PER_MB
  end

  def kbytes_to_mb
    self / KB_PER_MB
  end
end
