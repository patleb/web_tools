Rack::Attack.throttle('rescues:javascript:ip', limit: 5, period: 1.hour) do |req|
  if req.post? && req.path == MixRescue.routes[:rescue]
    req.ip # TODO use UA.browser as well
  end
end
