class Server < LibMainRecord
  enum provider: MixServer.config.available_providers

  def self.provisioned?(time = nil)
    ((time || Time.current) - current.created_at) > 10.minutes
  end

  def self.current
    @current ||= find_or_create_by! private_ip: Process.host.private_ip, provider: Setting[:server_provider]
  end

  def self.archive!
    # TODO clear_cron, discard, shutdown (sun specialize if private ip changed, then discard)
  end
end
