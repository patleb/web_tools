module ActiveRecord::Base::WithCreateState
  def create_or_update(*)
    @_new = false
    super
  end

  def _create_record(*)
    result = super
    new! if result
    result
  end

  def new?
    !!@_new
  end

  def new!
    @_new = true
    self
  end
end
