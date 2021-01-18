class Array
  def join!(separator=$,)
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
end
