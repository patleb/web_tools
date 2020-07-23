module MixUser
  module ViewHelper
    # TODO use Pundit consistently instead in views --> remove user_admin and user_logged_in
    def edit_user_link
      return unless Current.user_logged_in?
      css = 'edit_user_link'
      if defined?(MixAdmin) && Current.user.admin?
        css << ' pjax' if controller.try(:admin?)
        path = with_admin_controller(&:authorized_path_for.with(:edit, Current.user.class, Current.user))
        return unless path
      else
        css << ' pjax' unless controller.try(:admin?)
        path = edit_user_path
      end
      a_ class: css, href: path do
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
        span_ '.label.label-danger', t('mix_user.log_out')
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
      if defined?(::WebConsole) && Current.user.admin?
        console if params[:_remote_console].to_b
      end
    end

    def remote_console_link
      if defined?(::WebConsole) && Current.user.admin?
        a_('Console', href: '?_remote_console=1')
      end
    end

    def admin_link
      if defined?(MixAdmin) && Current.user.admin?
        link_to t('mix_user.admin'), RailsAdmin.root_path
      end
    end

    def with_admin_controller
      current_controller = Current.controller
      Current.controller = RailsAdmin::MainController.new unless current_controller.try(:admin?)
      yield Current.controller
    ensure
      Current.controller = current_controller
    end
  end
end
