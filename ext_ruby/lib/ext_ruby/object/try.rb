module ActiveSupport
  module Tryable
    # true         => true
    # nil || false => false
    alias_method :true?, :try

    # false       => true
    # nil || true => false
    def false?(*a, &b)
      try(*a, &b) == false
    end

    # nil || true => true
    # false       => false
    def nil_or_true?(*a, &b)
      !false?(*a, &b)
    end

    # nil || false => true
    # true         => false
    def nil_or_false?(*a, &b)
      !true?(*a, &b)
    end

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
  def true?(*a, &b)
    false
  end

  def false?(*a, &b)
    false
  end

  def nil_or_true?(*a, &b)
    true
  end

  def nil_or_false?(*a, &b)
    true
  end

  def nil?(*a, &b)
    true
  end

  def not_nil?(*a, &b)
    false
  end
end
