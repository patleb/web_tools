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
    false
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

  def upload?
    false
  end
end
