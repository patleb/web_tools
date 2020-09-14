class RailsAdmin::Config::Actions::Trash < RailsAdmin::Config::Actions::Base
  register_instance_option :link_weight, memoize: true do
    80
  end

  register_instance_option :link_icon, memoize: true do
    'fa fa-trash-o'
  end

  def visible?
    abstract_model.model.discardable? && super
  end

  def collection?
    true
  end

  def http_methods
    [:get]
  end

  def authorization_key
    :destroy
  end

  def searchable?
    true
  end
end
