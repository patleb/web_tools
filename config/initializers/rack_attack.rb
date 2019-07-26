Rack::Attack.throttle('javascript_rescues:ip', limit: 5, period: 1.hour) do |req|
  if req.post? && req.path == '/javascript_rescues'
    req.ip
  end
end
