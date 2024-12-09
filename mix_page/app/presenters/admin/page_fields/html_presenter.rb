module Admin
  module PageFields
    class HtmlPresenter < TextPresenter
      field :text, translated: true, type: :html
    end
  end
end
