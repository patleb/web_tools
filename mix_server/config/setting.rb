Setting.class_eval do
  def self.ftp_host_path
    "/#{stage}"
  end

  def self.authorized_keys
    Set.new([self[:owner_public_key]]).merge(self[:authorized_keys]).compact_blank
  end
end
