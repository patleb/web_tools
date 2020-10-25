Rack::Attack.throttle('rescues:javascripts:ip', limit: 5, period: 1.hour) do |req|
  if req.post? && req.path == MixRescue.js_routes[:rescue]
    req.ip
  end
end
