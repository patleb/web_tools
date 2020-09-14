class RailsAdmin::Config::Actions::Restore < RailsAdmin::Config::Actions::Base
  register_instance_option :link_weight, memoize: true do
    80
  end

  def collection?
    true
  end

  def http_methods
    [:post]
  end

  def authorization_key
    :destroy
  end

  def bulkable_trash?
    true
  end

  def navigable?
    false
  end
end
