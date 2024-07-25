class Module
  alias_method :cvars, :class_variables

  def cvar(name, *value)
    if block_given?
      class_variable_defined?(name) ? class_variable_get(name) : class_variable_set(name, yield)
    elsif value.empty?
      class_variable_get(name)
    else
      class_variable_set(name, *value)
    end
  end
end
