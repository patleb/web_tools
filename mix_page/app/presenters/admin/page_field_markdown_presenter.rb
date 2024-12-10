module Admin
  class PageFieldMarkdownPresenter < Admin::Model
    field :text, translated: true, type: :html
  end
end
