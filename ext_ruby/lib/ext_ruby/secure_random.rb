module SecureRandom
  UUID = /\A[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\z/.freeze

  def self.uuid_v1_to_timestamp(uuid)
    Time.at((uuid_v1_to_100nsecs(uuid).to_d - 122_192_928_000_000_000) / 10_000_000)
  end

  def self.uuid_v1_to_100nsecs(uuid)
    "#{uuid[15, 3]}#{uuid[9, 4]}#{uuid[0, 8]}".rjust(16, '0').to_i(16)
  end
end
