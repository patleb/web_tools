class UserSessionsController < Users::BaseController
  authenticate only: :destroy

  rate_limit to: 10, within: 3.minutes, only: :create,
    by: -> { [request.remote_ip, *user_agent].compact },
    with: -> { redirect_back alert: t('flash.too_many_attempts') }

  def skip_redirect_current_user
    request.path == MixUser::Routes.delete_session_path
  end

  def new
    @user = User.new
  end

  def create
    case params[:edit]
    when 'verified'
      send_email :verify_email, User.unverified
      redirect_back notice: t('flash.verify_email_sent')
    when 'deleted'
      render_404 and return unless MixUser.config.restorable?
      send_email :restore_user, User.discarded
      redirect_back notice: t('flash.restore_user_sent')
    when 'password'
      send_email :reset_password, User.verified
      redirect_back notice: t('flash.reset_password_sent')
    else
      if (@user = User.with_discarded.authenticate_by(create_params))
        create_session! @user
        redirect_back notice: t('flash.signed_in')
      else
        on_record_invalid :new
      end
    end
  rescue ActiveRecord::RecordInvalid, ArgumentError
    on_record_invalid :new
  end

  def destroy
    destroy_session! Current.user
    redirect_to root_path, status: :see_other, notice: t('flash.signed_out')
  end

  private

  def on_record_invalid(template)
    @user = User.new(email: create_params[:email])
    flash.now[:alert] = t('flash.failed_authentication')
    render template, status: :unprocessable_content
  end

  def create_params
    params.require(:user).permit(:email, :password)
  end
end
