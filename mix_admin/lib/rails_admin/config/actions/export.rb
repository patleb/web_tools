class RailsAdmin::Config::Actions::Export < RailsAdmin::Config::Actions::Base
  register_instance_option :link_weight, memoize: true do
    20
  end

  register_instance_option :link_icon, memoize: true do
    'fa fa-share-square-o'
  end

  def collection?
    true
  end

  def http_methods
    [:get, :post]
  end

  def bulkable?
    true
  end

  def searchable?
    true
  end

  def back_on_cancel?
    false
  end
end
