class RailsAdmin::Config::Actions::Base
  include RailsAdmin::Config::Proxyable
  include RailsAdmin::Config::Configurable

  register_instance_option :weight, memoize: true do
    0
  end

  register_instance_option :link_icon, memoize: true do
    ''
  end

  # User should override only custom_key (action name and route fragment change, allows for duplicate actions)
  register_instance_option :custom_key, memoize: true do
    key
  end

  # Should the action be visible
  def visible?
    abstract_model.model.visible? && authorized?(authorization_key, abstract_model, object)
  end

  # Is the action acting on the root level (Example: /admin/contact)
  def root?
    false
  end

  # Is the action on a model scope (Example: /admin/team/export)
  def collection?
    false
  end

  # Is the action on an object scope (Example: /admin/team/1/edit)
  def member?
    false
  end

  # Render via pjax?
  def pjax?
    true
  end

  # Model scoped actions only. You will need to handle params[:bulk_ids] in controller
  def bulkable?
    false
  end

  def bulkable_trash?
    false
  end

  # For Pundit and the like
  def authorization_key
    key.to_sym
  end

  # List of methods allowed. Note that you are responsible for correctly handling them in :controller action
  def http_methods
    [:get]
  end

  # Url fragment
  def route_fragment
    custom_key.to_s
  end

  # Controller action name
  def name
    custom_key.to_sym
  end

  # I18n key
  def i18n_key
    key
  end

  def main_name
    name.to_s
  end

  def navigable?
    true
  end

  def searchable?
    false
  end

  def back_on_cancel?
    true
  end

  # Off API.

  def key
    self.class.key
  end

  def self.key
    @key ||= name.to_s.demodulize.underscore.to_sym
  end
end
