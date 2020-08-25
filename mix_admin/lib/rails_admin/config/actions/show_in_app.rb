class RailsAdmin::Config::Actions::ShowInApp < RailsAdmin::Config::Actions::Base
  register_instance_option :link_icon, memoize: true do
    'fa fa-eye'
  end

  def member?
    true
  end

  def visible?
    super && object.respond_to?(:to_url)
  end

  def pjax?
    false
  end
end
