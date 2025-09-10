class UsersController < Users::BaseController
  def new
    render_404 and return unless MixUser.config.registerable?
    @user = User.new
  end

  def create
    render_404 and return unless MixUser.config.registerable?
    @user = User.new(create_params)
    User.transaction do
      @user.save!
      create_session! @user
    end
    send_email :verify_email
    redirect_back notice: t('flash.signed_up')
  rescue ActiveRecord::RecordInvalid
    on_record_invalid :new
  end

  def edit
    case params[:id]
    when 'verified'
      user = User.unverified.find_by_token_for! :verified, params[:token]
      user.verified!
      redirect_to root_path, notice: t('flash.verified')
    when 'deleted'
      render_404 and return unless MixUser.config.restorable?
      user = User.discarded.find_by_token_for! :deleted, params[:token]
      user.undiscard!
      redirect_to root_path, notice: t('flash.restored')
    when 'password'
      @user = User.verified.find_by_token_for! :password, params[:token]
    else
      on_invalid_link
    end
  rescue ActiveRecord::RecordInvalid
    on_record_invalid :edit
  rescue ActiveRecord::RecordNotFound, ActiveSupport::MessageVerifier::InvalidSignature
    on_invalid_link
  end

  def update
    @user = User.verified.find_by_token_for! :password, params[:token]
    User.transaction do
      @user.update! update_params
      destroy_session! @user
    end
    redirect_to MixUser::Routes.new_session_path, notice: t('flash.password_changed')
  rescue ActiveRecord::RecordInvalid
    on_record_invalid :edit
  rescue ActiveRecord::RecordNotFound, ActiveSupport::MessageVerifier::InvalidSignature
    on_invalid_link
  end

  private

  def on_record_invalid(template)
    @user.password = @user.password_confirmation = nil
    flash.now[:alert] = user_alert @user
    render template, status: :unprocessable_content
  end

  def on_invalid_link
    redirect_to root_path, alert: t('flash.invalid_link')
  end

  def create_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end

  def update_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
