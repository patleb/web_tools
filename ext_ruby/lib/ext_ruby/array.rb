class Array
  def mode
    return if empty?
    counts = each_with_object(Hash.new(0)){ |v, h| h[v] += 1 }
    max = counts.values.max
    counts.find{ |_v, count| count == max }.first
  end

  def average(init = 0, &block)
    return if empty?
    total = sum(init, &block)
    total / size.to_f
  end

  def stddev
    return if empty?
    Math.sqrt(variance)
  end

  def variance
    return if empty?
    mean = average
    total = map{ |v| (v - mean) ** 2 }.reduce(&:+)
    total / size.to_f
  end

  def median
    percentile(0.5)
  end

  def percentile(bucket)
    return if empty?
    sorted = sort
    last_i = sorted.size - 1
    upper_i = bucket.to_f * last_i
    lower_i = upper_i.floor
    if lower_i == last_i
      sorted.last
    else
      sorted[lower_i] + (upper_i % 1) * (sorted[lower_i + 1] - sorted[lower_i])
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
    return unless (i = index(old_value))
    self[i] = new_value
    self
  end

  def intersperse(element)
    flat_map{ |e| [e, element] }.tap(&:pop)
  end

  def closest(value)
    return if empty?
    values = Array.wrap(value)
    if values.size == 1
      min_by{ |e| (value - e).abs }
    elsif values.size < 10
      min_by{ |e| values.sub(Array.wrap(e)).sum{ |v| v * v } }
    else
      min_by{ |e| values.sub(Array.wrap(e)).sum(&:abs) }
    end
  end

  def neg
    map{ |x| -x }
  end

  def mul(value)
    map{ |x| x * value }
  end

  def div(value)
    map{ |x| x / value }
  end

  def sub(*others)
    (others.empty? ? self : [self, *others]).transpose.map{ |x| x.reduce(:-) }
  end

  def add(*others)
    (others.empty? ? self : [self, *others]).transpose.map(&:sum)
  end
end
