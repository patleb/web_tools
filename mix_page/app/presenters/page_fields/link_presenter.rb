module PageFields
  class LinkPresenter < PageFieldPresenter
    def render(**options)
      super **options do |options, actions|
        div_(options) {[
          actions,
          a_(href: record.to_url){ title },
        ]}
      end
    end

    def edit_url
      record.fieldable.admin_presenter.allowed_url(:edit)
    end
  end
end
