class RailsAdmin::Config::Actions::ShowInApp < RailsAdmin::Config::Actions::Base
  register_instance_option :link_icon, memoize: true do
    'fa fa-eye'
  end

  def member?
    true
  end

  def visible?
    super && (Current.controller.main_app.url_for(object) rescue false)
  end

  def pjax?
    false
  end
end
