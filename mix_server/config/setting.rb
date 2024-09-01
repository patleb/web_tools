Setting.class_eval do
  def self.ftp_host_path
    "/#{stage}"
  end
end
