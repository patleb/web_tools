Setting.class_eval do
  def self.ftp_host_path
    "/#{stage}"
  end

  def self.authorized_keys
    Set.new([self[:owner_public_key]]).merge(self[:authorized_keys]).compact_blank
  end

  def self.denied_ips
    %w(
      15.220.0.0/14
      15.222.0.0/15
      35.152.0.0/13
      35.160.0.0/12
      35.176.0.0/13
      45.55.0.0/16
      64.225.0.0/17
      72.10.174.8
      74.217.28.0/22
      104.236.0.0/16
      138.197.0.0/16
      157.245.0.0/16
      159.65.0.0/16
      162.19.0.0/16
      165.227.0.0/16
      172.98.64.0/19
      174.138.0.0/17
      3.98.92.111
    )
  end
  class << self
    alias_method :default_denied_ips, :denied_ips
  end
end
