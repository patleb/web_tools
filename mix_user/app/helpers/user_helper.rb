# frozen_string_literal: true

module UserHelper
  def user_login_link
    return if Current.logged_in?
    li_ a_('.user_login', t('link.log_in'), href: MixUser::Routes.new_session_path)
  end

  def user_logout_button
    return unless Current.logged_in?
    form_ '.user_logout', action: MixUser::Routes.delete_session_path, remote: true do
      input_ '.btn.btn-active.btn-error.btn-xs', type: 'submit', value: t('link.log_out')
    end
  end

  def user_links
    i18n = i18n_for('link' => [:back, :sign_up, :log_in, :forgot_password, :missing_confirm])
    links = []
    case controller_name
    when 'users'
      links << a_(i18n[:log_in], href: MixUser::Routes.new_session_path)
    when 'user_sessions'
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
