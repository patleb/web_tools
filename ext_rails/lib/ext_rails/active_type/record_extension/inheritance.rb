ActiveType::RecordExtension::Inheritance::ClassMethods.module_eval do
  alias_method :old_model_name, :model_name
  def model_name
    name ? super : old_model_name
  end
end
