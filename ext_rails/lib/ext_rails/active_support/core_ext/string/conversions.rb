class String
  def to_const!
    ActiveSupport::Dependencies.constantize(self)
  end

  def to_const
    ActiveSupport::Dependencies.safe_constantize(self)
  end
end
