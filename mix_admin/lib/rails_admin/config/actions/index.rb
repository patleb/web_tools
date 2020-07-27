class RailsAdmin::Config::Actions::Index < RailsAdmin::Config::Actions::Base
  register_instance_option :link_icon, memoize: true do
    'fa fa-th-list'
  end

  def collection?
    true
  end

  def http_methods
    [:get, :post, :put, :delete] # prevent 404 on redirect
  end

  def route_fragment
    ''
  end

  def searchable?
    true
  end
end
