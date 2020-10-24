class Credential < LibRecord
  enum type: MixCredential.config.available_types

  def self.find_by_token!(token)
    raise NotImplementedError
  end
end
