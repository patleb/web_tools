class RailsAdmin::Config::Actions::Chart < RailsAdmin::Config::Actions::Base
  register_instance_option :weight, memoize: true do
    10
  end

  register_instance_option :link_icon, memoize: true do
    'fa fa-bar-chart'
  end

  def collection?
    true
  end

  def http_methods
    [:get, :post]
  end

  def searchable?
    true
  end

  def back_on_cancel?
    false
  end
end
