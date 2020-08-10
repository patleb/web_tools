require 'active_type/record_extension/inheritance'

# TODO https://github.com/makandra/active_type/blob/master/CHANGELOG.md --> 1.4.0, i18n key
ActiveType::RecordExtension::Inheritance::ClassMethods.module_eval do
  alias_method :old_model_name, :model_name
  def model_name
    name ? super : old_model_name
  end
end
