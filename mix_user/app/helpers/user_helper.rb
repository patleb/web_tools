module UserHelper
  def user_role_select
    return unless Current.user.role_admin?
    param_select :role, Current.user.as_role, Current.user.available_roles.keys, 'person-badge' do |role|
      User.human_attribute_name("role.#{role}", default: role.to_s.humanize)
    end
  end

  def user_link
    li_ do
      if user_login_link?
        a_ '.user_link.user_login', span_(t 'link.log_in'), href: MixUser::Routes.new_session_path
      else
        form_ '.user_link.user_logout', action: MixUser::Routes.delete_session_path, remote: true do
          input_ type: 'submit', value: t('link.log_out')
        end
      end
    end
  end

  def user_login_link?
    !Current.logged_in?
  end

  def user_links
    return unless controller.is_a? Users::BaseController
    i18n = i18n_for('link' => [:back, :sign_up, :log_in, :forgot_password, :missing_confirm])
    links = []
    case controller
    when UsersController
      links << a_(i18n[:log_in], href: MixUser::Routes.new_session_path)
    when UserSessionsController
      if params[:edit].present?
        links << a_(i18n[:back], href: MixUser::Routes.new_session_path)
      elsif MixUser.config.registerable?
        links << a_(i18n[:sign_up], href: MixUser::Routes.new_path)
      end
      if params[:edit] != 'password'
        links << a_(i18n[:forgot_password], href: MixUser::Routes.password_path)
      end
      if params[:edit] != 'verified'
        links << a_(i18n[:missing_confirm], href: MixUser::Routes.verified_path)
      end
    end
    ul_ '.menu', unless: links.empty? do
      links.map{ |link| li_ link }
    end
  end
end
