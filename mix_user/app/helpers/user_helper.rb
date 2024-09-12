# frozen_string_literal: true

module UserHelper
  def user_link
    if Current.logged_in?
      form_ '.user_link.user_logout', action: MixUser::Routes.delete_session_path, remote: true do
        input_ type: 'submit', value: t('link.log_out')
      end
    else
      a_('.user_link.user_login', t('link.log_in'), href: MixUser::Routes.new_session_path)
    end
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
