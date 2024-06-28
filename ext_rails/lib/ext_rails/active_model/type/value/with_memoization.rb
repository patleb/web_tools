module ActiveModel::Type::Value::WithMemoization
  private

  def memoize(method_name, *args)
    values = (@_memoize ||= {})[method_name] ||= {}
    args.map!(&:object_id)
    if values.has_key? args
      values[args]
    else
      values[args] = yield
    end
  end
end

ActiveModel::Type::Value.prepend ActiveModel::Type::Value::WithMemoization
