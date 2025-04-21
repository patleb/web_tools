# frozen_string_literal: false

class Array
  class SizeMismatch < ::StandardError; end

  # Numo::NArray#to_a.to_s.tr(' ', '').tr('[', '{').tr(']', '}')
  def to_sql(*shape)
    raise SizeMismatch if self[0].is_a? Array
    raise SizeMismatch unless (size = shape.reduce(&:*) || 0) == self.size
    return '{}' if (ndims = shape.size) == 0
    return '{' * ndims + '}' * ndims if size == 0
    i = 0
    dim_i = 0
    dim_n = ndims - 1
    counts = shape.dup
    sql = ''
    loop do
      loop do
        sql << '{'
        break if dim_i == dim_n
        dim_i += 1
      end
      loop do
        sql << self[i].to_s
        i += 1
        break if (counts[dim_i] -= 1) == 0
        sql << ','
      end
      loop do
        sql << '}'
        return sql if dim_i == 0
        unless (counts[dim_i - 1] -= 1) == 0
          (dim_i..dim_n).each{ |d| counts[d] = shape[d] }
          sql << ','
          break
        end
        dim_i -= 1
      end
    end
  end

  def mode
    return if empty?
    counts = each_with_object(Hash.new(0)){ |v, h| h[v] += 1 }
    max = counts.values.max
    counts.find{ |_v, count| count == max }.first
  end

  def average(&block)
    return if empty?
    total = sum(&block)
    total / size.to_f
  end
  alias_method :mean, :average

  def stddev(...)
    return if empty?
    Math.sqrt(variance(...))
  end

  def variance(mean = average)
    return if empty?
    total = sum{ |v| (v - mean) ** 2 }
    total / size.to_f
  end
  alias_method :var, :variance

  def median_filter(window = 3)
    return dup unless size > window
    radius = (window - 1) / 2
    window = Array.new(radius + 1, first).concat(self[0...radius] || [])
    upper  = nil
    size.times.map do |i|
      window.shift
      upper = self[i + radius] || upper
      window << upper
      window.sort[radius]
    end
  end

  def median
    percentile(0.5)
  end

  def percentile(bucket)
    return if empty?
    bucket /= 100.0 if bucket > 1.0
    values = sort
    last_i = values.size - 1
    upper_i = bucket.to_f * last_i
    lower_i = upper_i.floor
    if lower_i == last_i
      values.last
    else
      values[lower_i] + (upper_i % 1) * (values[lower_i + 1] - values[lower_i])
    end
  end

  def join!(separator = $,)
    reject(&:blank?).join(separator)
  end

  def except(*values)
    self - values
  end

  def insert_before(anchor, value)
    insert((index(anchor) || -1), value)
  end

  def insert_after(anchor, value)
    insert((index(anchor) || -2) + 1, value)
  end

  def switch(old_value, new_value)
    arr = dup
    arr.switch! old_value, new_value
    arr
  end

  def switch!(old_value, new_value)
    return self unless (i = index(old_value))
    self[i] = new_value
    self
  end

  def intersperse(element)
    flat_map{ |e| [e, element] }.tap(&:pop)
  end

  def neg
    map{ |x| -x }
  end

  def mul(value)
    return map{ |x| x * value } unless value.is_a? Array
    raise SizeMismatch if size != value.size
    map.with_index{ |x, i| x * value[i] }
  end

  def div(value)
    return map{ |x| x / value } unless value.is_a? Array
    raise SizeMismatch if size != value.size
    map.with_index{ |x, i| x / value[i] }
  end

  def sub(other, *others)
    if others.empty?
      return map{ |x| x - other } unless other.is_a? Array
      raise SizeMismatch if size != other.size
      map.with_index{ |x, i| x - other[i] }
    else
      [self, other, *others].transpose.map{ |x| x.reduce(:-) }
    end
  end

  def add(other, *others)
    if others.empty?
      return map{ |x| x + other } unless other.is_a? Array
      raise SizeMismatch if size != other.size
      map.with_index{ |x, i| x + other[i] }
    else
      [self, other, *others].transpose.map(&:sum)
    end
  end

  def l0(other = nil)
    return sum{ |x| (!x.zero?).to_f } if other.nil?
    raise SizeMismatch if size != other.size
    sum_with_index{ |x, i| (x != other[i]).to_f }
  end

  def l1(other = nil)
    return sum(&:abs) if other.nil?
    raise SizeMismatch if size != other.size
    sum_with_index{ |x, i| (x - other[i]).abs }
  end

  def l2(...)
    Math.sqrt(l2_squared(...))
  end

  def l2_squared(other = nil)
    return sum{ |x| x ** 2 } if other.nil?
    raise SizeMismatch if size != other.size
    sum_with_index{ |x, i| (x - other[i]) ** 2 }
  end

  def l_infinity(other = nil)
    return map(&:abs).max || 0.0 if other.nil?
    raise SizeMismatch if size != other.size
    map.with_index{ |x, i| (x - other[i]).abs }.max || 0.0
  end
  alias_method :l_inf, :l_infinity

  def sum_with_index(&block)
    map.with_index(&block).sum
  end
end
