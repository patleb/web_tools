module Turbolinks
  module Redirection
    extend ActiveSupport::Concern

    included do
      before_action :set_turbolinks_location_header_from_session
    end

    def redirect_to(url = {}, options = {})
      turbolinks = options.delete(:turbolinks)

      super.tap do
        if turbolinks.present? && request.xhr? && !request.get?
          visit_location_with_turbolinks(location, turbolinks)
        elsif request.headers["Turbolinks-Referrer"]
          store_turbolinks_location_in_session(location)
        end
      end
    end

    private

    def visit_location_with_turbolinks(location, action)
      visit_options = {
        action: action.to_s == "advance" ? action : "replace"
      }
      self.status = 200
      self.response_body = <<~JS
        Turbolinks.clearCache()
        Turbolinks.visit(#{location.to_json}, #{visit_options.to_json})
      JS
      response.content_type = "text/javascript"
      response.headers["X-Xhr-Redirect"] = location
    end

    def store_turbolinks_location_in_session(location)
      session[:_turbolinks_location] = location if session
    end

    def set_turbolinks_location_header_from_session
      if session && session[:_turbolinks_location]
        response.headers["Turbolinks-Location"] = session.delete(:_turbolinks_location)
      end
    end
  end
end
