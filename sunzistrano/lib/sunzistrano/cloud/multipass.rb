module Cloud::Multipass
  def multipass_server_ips(filter)
    multipass_servers(filter).values
  end

  def multipass_servers(filter)
    Host.domains[:virtual].select{ |name, _ip| name.include? filter }
  end
end
