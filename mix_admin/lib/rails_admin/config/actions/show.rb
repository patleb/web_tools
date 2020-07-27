class RailsAdmin::Config::Actions::Show < RailsAdmin::Config::Actions::Base
  register_instance_option :link_icon, memoize: true do
    'fa fa-info-circle'
  end

  def member?
    true
  end

  def route_fragment
    ''
  end
end
