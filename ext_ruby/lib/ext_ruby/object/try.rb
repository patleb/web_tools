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
      !!try(...)
    end

    # false       => true
    # nil || true => false
    def false?(...)
      try(...) == false
    end

    # nil || falsy => true
    # truthy       => false
    def falsy?(...)
      !try(...)
    end

    # nil || true => true
    # false       => false
    def nil_or_true?(...)
      (result = try(...)).nil? || result == true
    end

    # nil || truthy => true
    # false         => false
    def nil_or_truthy?(...)
      (result = try(...)).nil? || !!result
    end

    # nil || false => true
    # true         => false
    alias_method :nil_or_false?, :falsy?

    # nil || falsy => true
    # truthy       => false
    alias_method :nil_or_falsy?, :falsy?
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
end
