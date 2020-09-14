class RailsAdmin::Config::Actions::Clone < RailsAdmin::Config::Actions::Base
  register_instance_option :link_weight, memoize: true do
    20
  end

  register_instance_option :link_icon, memoize: true do
    'fa fa-clone'
  end

  def member?
    true
  end

  def http_methods
    [:get]
  end

  def back_on_cancel?
    false
  end
end
