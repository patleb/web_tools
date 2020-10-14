class RailsAdmin::Config::Actions::Sort < RailsAdmin::Config::Actions::Base
  register_instance_option :link_weight, memoize: true do
    30
  end

  register_instance_option :link_icon, memoize: true do
    'fa fa-sort-amount-asc'
  end

  def visible?
    abstract_model.model.listable? && authorized?(:index, abstract_model) && super
  end

  def collection?
    true
  end

  def http_methods
    [:get, :put]
  end

  def authorization_key
    :edit
  end

  def searchable?
    true
  end
end
