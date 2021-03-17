class Symbol
  def with(*args, **options, &block)
    -> (caller, *rest) { caller.send(self, *rest, *args, **options, &block) }
  end
end
