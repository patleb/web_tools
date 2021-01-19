class CredentialsController < ActionController::API
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
