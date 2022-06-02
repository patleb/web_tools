module ActionController::Base::WithXhrRedirect
  extend ActiveSupport::Concern

  included do
    before_action :set_xhr_redirect
  end

  def redirect_to(*)
    super.tap do
      if request.xhr?
        response.headers['X-Xhr-Redirect'] = location
        session.m_access(:_xhr_redirect){ location }
      end
    end
  end

  private

  def set_xhr_redirect
    if session && session.m_access(:_xhr_redirect)
      response.headers['X-Xhr-Redirect'] = session.m_clear(:_xhr_redirect)
    end
  end
end

ActionController::Base.include ActionController::Base::WithXhrRedirect
