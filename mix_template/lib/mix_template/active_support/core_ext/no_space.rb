module NoSpace
  def no_space!
    @_no_space = true
    self
  end

  def no_space?
    @_no_space
  end
end

class String
  include NoSpace
end

class Symbol
  include NoSpace
end
