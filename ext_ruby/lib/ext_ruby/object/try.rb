module ActiveSupport
  module Tryable
    # true         => true
    # nil || false => false
    def true?(...)
      try(...) == true
    end

    # truthy       => true
    # nil || falsy => false
    def truthy?(...)
      try(...).to_b
    end

    # false       => true
    # nil || true => false
    def false?(...)
      try(...) == false
    end

    # nil || falsy => true
    # truthy       => false
    def falsy?(...)
      !truthy?(...)
    end

    # nil || true => true
    # false       => false
    def nil_or_true?(...)
      !false?(...)
    end

    # nil || truthy => true
    # !nil && falsy => false
    def nil_or_truthy?(...)
      (result = try(...)).nil? || result.to_b
    end

    # nil || false => true
    # true         => false
    def nil_or_false?(...)
      !true?(...)
    end

    # nil || falsy => true
    # truthy       => false
    alias_method :nil_or_falsy?, :falsy?

    # nil           => true
    # false || true => false
    def nil?(*a, **o, &b)
      a.empty? ? super : try(*a, **o, &b).nil?
    end

    # false || true => true
    # nil           => false
    def not_nil?(...)
      !nil?(...)
    end
  end
end

class NilClass
  def true?(...)
    false
  end

  def truthy?(...)
    false
  end

  def false?(...)
    false
  end

  def falsy?(...)
    true
  end

  def nil_or_true?(...)
    true
  end

  def nil_or_truthy?(...)
    true
  end

  def nil_or_false?(...)
    true
  end

  def nil_or_falsy?(...)
    true
  end

  def nil?(...)
    true
  end

  def not_nil?(...)
    false
  end
end
