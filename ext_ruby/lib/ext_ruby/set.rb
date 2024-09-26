class Set
  def except(*values)
    self - values
  end

  def switch(old_value, new_value)
    set = dup
    set.switch! old_value, new_value
    set
  end

  def switch!(old_value, new_value)
    return self unless include? old_value
    delete(old_value)
    add(new_value)
    self
  end
end
