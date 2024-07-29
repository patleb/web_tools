class Object
  alias_method :ivars, :instance_variables
  alias_method :ivar_defined?, :instance_variable_defined?

  def remove_ivar(name)
    remove_instance_variable(name) if ivar_defined? name
  end

  def ivar(name, *value)
    if block_given?
      ivar_defined?(name) ? instance_variable_get(name) : instance_variable_set(name, yield)
    elsif value.empty?
      instance_variable_get(name)
    else
      instance_variable_set(name, *value)
    end
  end
end
