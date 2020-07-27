class RailsAdmin::Config::Actions::Report < RailsAdmin::Config::Actions::Base
  register_instance_option :link_icon, memoize: true do
    'fa fa-file-pdf-o'
  end

  def member?
    true
  end

  def http_methods
    [:get]
  end

  def navigable?
    false
  end
end
