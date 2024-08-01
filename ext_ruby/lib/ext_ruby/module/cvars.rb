class Module
  alias_method :cvars, :class_variables
  alias_method :cvar_defined?, :class_variable_defined?

  def remove_cvar(name)
    remove_class_variable(name) if cvar_defined? name
  end

  def cvar(name, *value)
    if block_given?
      cvar_defined?(name) ? class_variable_get(name) : class_variable_set(name, yield)
    elsif value.empty?
      class_variable_get(name)
    else
      class_variable_set(name, *value)
    end
  end
end
