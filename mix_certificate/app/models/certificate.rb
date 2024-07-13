class Certificate < LibMainRecord
  enum! type: MixCertificate.config.available_types

  def self.find_by_token!(token)
    raise NotImplementedError
  end
end
