module ActionDispatch::Request::Session::WithMemoizedAt
  extend ActiveSupport::Concern

  prepended do
    def m_access(key, timeout: 5, force: false)
      if force || (written_at = self["_#{key}_at"]).blank? || (Time.current - Time.parse(written_at)) > timeout
        if block_given?
          value = self[key] = yield
          self["_#{key}_at"] = Time.current.utc.to_s
        else
          m_clear(key)
          value = nil
        end
      else
        value = self[key]
      end
      value
    end

    def m_clear(key)
      delete("_#{key}_at")
      delete(key)
    end
  end
end

ActionDispatch::Request::Session.prepend ActionDispatch::Request::Session::WithMemoizedAt
