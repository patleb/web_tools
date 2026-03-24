class CertificatesController < ActionController::API
  rate_limit to: 5, within: 2.minutes

  def show
    record = certificate_class.select(:challenge).find_by_token! params[:token]
    render plain: record.challenge
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  private

  def certificate_class
    @certificate_class ||= Certificate.new(type: params[:type]).class
  end
end
