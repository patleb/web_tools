class RailsAdmin::Config::Actions::BulkDelete < RailsAdmin::Config::Actions::Base
  register_instance_option :link_weight, memoize: true do
    100
  end

  def collection?
    true
  end

  def http_methods
    [:get, :post, :put, :delete]
  end

  def authorization_key
    :delete
  end

  def bulkable?
    true
  end

  def bulkable_trash?
    true
  end

  def main_name
    'delete'
  end

  def navigable?
    false
  end
end
