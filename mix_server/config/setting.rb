Setting.class_eval do
  def self.ftp_host_path
    "/#{app}/#{env}"
  end
end
