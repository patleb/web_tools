module MixUser
  module ViewHelper
    def edit_user_link
      return unless Current.user_logged_in?
      css = 'edit_user_link'
      if defined?(MixAdmin) && Current.user.admin?
        css << ' pjax' if controller.try(:admin?)
        path = admin_path_for(:edit, Current.user)
        title = t('user.admin')
      elsif MixUser.config.devise_modules.include? :registerable
        css << ' pjax' unless controller.try(:admin?)
        path = edit_user_path
      else
        return
      end
      a_ class: css, href: path, title: title do
        span_(Current.user.email)
      end
    end

    def login_link
      return if Current.user_logged_in?
      link_to t('devise.sessions.new.sign_in'), login_path, class: 'pjax'
    end

    def logout_link
      return unless Current.user_logged_in?
      a_ href: logout_path, data: { method: logout_method } do
        span_ '.label.label-danger', t('user.log_out')
      end
    end

    def edit_user_path
      @_edit_user_path ||= main_app.edit_user_registration_path
    end

    def login_path
      @_login_path ||= main_app.new_user_session_path
    end

    def logout_path
      @_logout_path ||= main_app.destroy_user_session_path
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
        a_('Console', href: '?_remote_console=1')
      end
    end

    def admin_link
      if defined?(MixAdmin) && Current.user.admin?
        link_to t('user.admin'), RailsAdmin.root_path
      end
    end
  end
end
