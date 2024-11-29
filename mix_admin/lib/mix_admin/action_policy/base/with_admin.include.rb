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
    (show? || edit?) && (klass? || record.respond_to?(:to_url))
  end

  def new?
    false
  end
  alias_method :create?, :new?

  def edit?
    false
  end
  alias_method :update?, :edit?

  def delete?
    false
  end
  alias_method :destroy?, :delete?

  def trash?
    return false unless delete?
    return false if klass.undiscardable? && Current.discarded?
    return false if record&.discarded? && Current.undiscarded?
    true
  end

  def restore?
    trash?
  end
end
