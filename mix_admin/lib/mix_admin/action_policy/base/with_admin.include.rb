module ActionPolicy::Base::WithAdmin
  def index?
    false
  end

  def export?
    false
  end

  def show?
    false
  end

  def show_in_app?
    (show? || edit?) && (model? || record.respond_to?(:to_url))
  end

  def new?
    false
  end

  def edit?
    false
  end

  def delete?
    false
  end

  def trash?
    return false unless delete?
    return false if klass.undiscardable? && Current.discarded?
    return false if record&.discarded? && Current.undiscarded?
    true
  end

  def restore?
    trash?
  end

  protected

  def model?
    klass?
  end
end
