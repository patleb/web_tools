module ActiveSupport
  module Tryable
    # true         => true
    # nil || false => false
    def true?(*a, &b)
      try(*a, &b) == true
    end

    # truthy       => true
    # nil || falsy => false
    def truthy?(*a, &b)
      try(*a, &b).to_b
    end

    # false       => true
    # nil || true => false
    def false?(*a, &b)
      try(*a, &b) == false
    end

    # nil || falsy => true
    # truthy       => false
    def falsy?(*a, &b)
      !truthy?(*a, &b)
    end

    # nil || true => true
    # false       => false
    def nil_or_true?(*a, &b)
      !false?(*a, &b)
    end

    # nil || truthy => true
    # !nil && falsy => false
    def nil_or_truthy?(*a, &b)
      (result = try(*a, &b)).nil? || result.to_b
    end

    # nil || false => true
    # true         => false
    def nil_or_false?(*a, &b)
      !true?(*a, &b)
    end

    # nil || falsy => true
    # truthy       => false
    alias_method :nil_or_falsy?, :falsy?

    # nil           => true
    # false || true => false
    def nil?(*a, &b)
      a.empty? ? super : try(*a, &b).nil?
    end

    # false || true => true
    # nil           => false
    def not_nil?(*a, &b)
      !nil?(*a, &b)
    end
  end
end

class NilClass
  def true?(*)
    false
  end

  def truthy?(*)
    false
  end

  def false?(*)
    false
  end

  def falsy?(*)
    true
  end

  def nil_or_true?(*)
    true
  end

  def nil_or_truthy?(*)
    true
  end

  def nil_or_false?(*)
    true
  end

  def nil_or_falsy?(*)
    true
  end

  def nil?(*)
    true
  end

  def not_nil?(*)
    false
  end
end
