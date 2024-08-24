# frozen_string_literal: true

module ActionController::Base::WithUser
  extend ActiveSupport::Concern

  class_methods do
    def authenticate(**)
      before_action(:require_authentication, **)
    end

    def no_authentication(**)
      before_action(:require_no_authentication, **)
    end
  end

  private

  def require_authentication
    redirect_current_user do
      redirect_to MixUser::Routes.new_session_path, alert: t('flash.unauthenticated') if Current.user.nil?
    end
  end

  def require_no_authentication
    redirect_current_user do
      redirect_to root_path, notice: t('flash.already_authenticated') if Current.user.active?
    end
  end

  def redirect_current_user
    return if try(:skip_redirect_current_user)
    yield
    return if performed?
    return redirect_to_discarded if Current.user.discarded?
    redirect_to_unverified if Current.user.unverified?
  end

  def redirect_to_unverified
    return if request.path == MixUser::Routes.new_session_path && params[:edit] == 'verified'
    redirect_to MixUser::Routes.verified_path, alert: t('flash.signed_up_but_inactive')
  end

  def redirect_to_discarded
    return if request.path == MixUser::Routes.new_session_path && params[:edit] == 'deleted'
    if MixUser.config.restorable?
      redirect_to MixUser::Routes.deleted_path, alert: t('flash.signed_up_but_disabled')
    else
      redirect_to root_path, alert: t('flash.signed_up_but_disabled')
    end
  end

  def user_alert(record)
    alert = t('flash.alert', name: record.model_name.human, action: t(action_name, scope: 'flash.action'))
    if record.try(:errors).present?
      alert += ExtRails::ERROR_SEPARATOR + record.errors.full_messages.join(ExtRails::ERROR_SEPARATOR)
    end
    helpers.simple_format! alert
  end

  def user_notice(record)
    name = record.is_a?(String) ? name : record.model_name.human
    t('flash.notice', name: name, action: t(action_name, scope: 'flash.action'))
  end
end
