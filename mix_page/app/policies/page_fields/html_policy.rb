module PageFields
  class HtmlPolicy < PageFieldPolicy
    def upload?
      edit?
    end
  end
end
