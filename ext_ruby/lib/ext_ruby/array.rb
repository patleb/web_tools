class Array
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

  def insert_after(anchor, value)
    insert((index(anchor) || -1) + 1, value)
  end

  def sub(old_value, new_value)
    arr = dup
    arr.sub! old_value, new_value
    arr
  end

  def sub!(old_value, new_value)
    return unless (i = index(old_value))
    self[i] = new_value
    self
  end

  def intersperse(element)
    flat_map{ |e| [e, element] }.tap(&:pop)
  end

  def unsplat
    if size == 1 && first.is_a?(Array)
      first.dup
    else
      dup
    end
  end

  def unsplat!
    if size == 1 && first.is_a?(Array)
      replace(first)
    else
      self
    end
  end
end
