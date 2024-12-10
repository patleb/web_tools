module Admin
  module PageFields
    class HtmlPresenter < Admin::PageFieldPresenter
      nests :markdown, as: :text, translated: true
    end
  end
end
