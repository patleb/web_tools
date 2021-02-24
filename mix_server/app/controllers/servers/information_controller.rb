module Servers
  class InformationController < ActionController::API
    def show_ip
      render plain: request.remote_ip
    end
  end
end
