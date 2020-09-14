class RailsAdmin::Config::Actions::Edit < RailsAdmin::Config::Actions::Base
  register_instance_option :link_weight, memoize: true do
    10
  end

  register_instance_option :link_icon, memoize: true do
    'fa fa-pencil'
  end

  def member?
    true
  end

  def http_methods
    [:get, :put]
  end

  def back_on_cancel?
    false
  end
end
