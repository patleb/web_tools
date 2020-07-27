class RailsAdmin::Config::Model::Fields::ForeignKey < RailsAdmin::Config::Model::Fields::Integer
  register_instance_option :pretty_value do
    "#{associated_model_name} ##{value}"
  end

  register_instance_option :index_value do
    foreign_key_link
  end

  register_instance_option :associated_model_name, memoize: true do
    name = self.name.to_s.delete_suffix('_id').camelize
    if (namespace = abstract_model.model_name.deconstantize).present?
      namespaced_name = "#{namespace}::#{name}"
      name = namespaced_name if ActiveSupport::Dependencies.safe_constantize(namespaced_name)
    end
    name
  end

  register_instance_option :foreign_key_name, memoize: true do
    unless (name = self.name.to_s).end_with? '_id'
      name = "#{name}_id"
    end
    name
  end

  def value
    object.safe_send(foreign_key_name)
  end

  def foreign_key_link
    if (path = authorized_path_for(:show, associated_model_name, object, foreign_key_name))
      a_ '.pjax', pretty_value, href: path
    elsif (path = authorized_path_for(:edit, associated_model_name, object, foreign_key_name))
      a_ '.pjax', pretty_value, href: path
    else
      pretty_value
    end
  end
end
