module Admin
  module PageFields
    class LinkPresenter < Admin::PageFieldPresenter
      fallback_location{ presenter.fieldable.to_url }

      nests :fieldable, as: :title, translated: true
    end
  end
end
