module UsersHelper
  def devise_flash_messages
    return if resource.errors.empty?
    flash[:error] = admin_error_notice(resource, resource.model_name.human)
  end

  def devise_error_messages
    return if resource.errors.empty?
    sentence = I18n.t('errors.messages.not_saved', count: resource.errors.count, resource: resource.class.model_name.human.downcase)
    div_('.devise-bs.alert.alert-danger.alert-block') {[
      button_('.close', '&times;', escape: false, type: 'button', data: { dismiss: 'alert' }),
      h5_('.alert-title', sentence.capitalize),
      ul_ do
        resource.errors.full_messages.map do |msg|
          li_ msg
        end
      end
    ]}
  end

  def edit_user_link
    return unless Current.user_logged_in?
    css = 'edit_user_link'
    admin_controller = controller.try(:admin?)
    if defined?(MixAdmin) && !(Current.user_role? && !admin_controller) && Current.user.admin?
      css << ' pjax' if admin_controller
      path = admin_path_for(:edit, Current.user)
      title = t('user.admin')
    elsif MixUser.config.devise_modules.include? :registerable
      css << ' pjax' unless admin_controller
      path = edit_user_path
    else
      return
    end
    a_(class: css, href: path, title: title) {[
      i_('.fa.fa-user'),
      span_(Current.user.email)
    ]}
  end

  def login_link
    return if Current.user_logged_in?
    a_ '.pjax', href: login_path do
      span_ '.label.label-primary', t('devise.sessions.new.sign_in')
    end
  end

  def logout_link
    return unless Current.user_logged_in?
    a_ href: logout_path, data: { method: logout_method } do
      span_ '.label.label-danger', t('user.log_out')
    end
  end

  def edit_user_path
    @@_edit_user_path ||= main_app.edit_user_registration_path
  end

  def login_path
    @@_login_path ||= main_app.new_user_session_path
  end

  def logout_path
    @@_logout_path ||= main_app.destroy_user_session_path
  end

  def logout_method
    [Devise.sign_out_via].flatten.first
  end

  def remote_console
    if defined?(::WebConsole) && Current.user.deployer?
      console if params[:_remote_console].to_b
    end
  end

  def remote_console_link
    if defined?(::WebConsole) && Current.user.deployer?
      a_(href: '?_remote_console=1') {[
        i_('.fa.fa-terminal'),
        span_('Console'),
      ]}
    end
  end

  def admin_link
    if defined?(MixAdmin) && Current.user.admin?
      a_ href: RailsAdmin.root_path do
        span_ '.label.label-primary', t('user.admin')
      end
    end
  end
end
