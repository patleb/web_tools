class RailsAdmin::Config::Actions::New < RailsAdmin::Config::Actions::Base
  register_instance_option :link_weight, memoize: true do
    30
  end

  register_instance_option :link_icon, memoize: true do
    'fa fa-plus'
  end

  def collection?
    true
  end

  def http_methods
    [:get, :post] # NEW / CREATE
  end

  def back_on_cancel?
    false
  end
end
