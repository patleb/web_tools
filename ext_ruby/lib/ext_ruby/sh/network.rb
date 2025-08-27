### References
# https://github.com/rsp/scripts/blob/master/externalip
# https://github.com/rsp/scripts/blob/master/internalip

module Sh::Network
  def http_code_get(url, username: nil, password: nil)
    options = "-o - -s -w '%{http_code}\n'".escape_newlines
    cmd = http_get(url, username: username, password: password, options: options)
    "#{cmd} && echo"
  end

  def http_get(url, username: nil, password: nil, options: nil)
    if username && password
      basic_auth = "-u #{username}:#{password}"
    end
    "/usr/bin/curl #{basic_auth} --insecure --silent #{options} '#{url}'"
  end

  def default_interface
    "route | grep '^default' | grep -o '[^ ]*$'"
  end

  def public_ip
    'curl -s http://checkip.amazonaws.com/ && echo'
  end

  def private_ip
    "hostname -I | awk '{print $NF; exit}'"
  end

  def mac_address
    "cat /sys/class/net/*/address | head -n1"
  end
end
