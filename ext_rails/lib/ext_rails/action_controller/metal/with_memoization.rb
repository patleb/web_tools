module ActionController::WithMemoization
  # NOTE referential equality (#equal?) is used instead of value equality (#eql? or #==)
  def memoize(context, method_name, *args)
    values = ((@_memoize ||= {})[context.object_id] ||= {})[method_name] ||= {}
    args.map!(&:object_id)
    if values.has_key? args
      values[args]
    else
      values[args] = yield
    end
  end
end
