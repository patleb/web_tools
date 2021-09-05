class Symbol
  def with(*args, **options, &block)
    -> (caller, *rest) { caller.send(self, *rest, *args, **options, &block) }
  end

  def pluralize(*args)
    to_s.pluralize(*args)
  end

  def singularize(*args)
    to_s.singularize(*args)
  end
end
