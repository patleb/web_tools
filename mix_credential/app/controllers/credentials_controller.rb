class CredentialsController < ActionController::API
  include ActionController::RequestForgeryProtection

  protect_from_forgery with: :exception

  def show
    record = credential_class.select(:challenge).find_by_token! params[:token]
    render plain: record.challenge
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  private

  def credential_class
    @credential_class ||= Credential.new(type: params[:type]).class
  end
end
