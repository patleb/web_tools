class Server < LibMainRecord
  enum provider: MixServer.config.available_providers

  def self.current
    @current ||= find_or_create_by! id: Process.host.machine_id do |record|
      record.private_ip = Process.host.private_ip
      record.provider = Setting[:server_provider]
    end
  end
end
