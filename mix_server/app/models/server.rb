class Server < LibMainRecord
  enum provider: MixServer.config.available_providers

  def self.current_version
    @current_version ||= begin
      version_path = Rails.root.join('REVISION')
      version_path.exist? ? version_path.read.first(8) : '0.1.0'
    end
  end

  def self.current
    @current ||= find_or_create_by! private_ip: Process.host.private_ip, provider: Setting[:server_provider]
  end
end
