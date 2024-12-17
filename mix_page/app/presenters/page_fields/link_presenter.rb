module PageFields
  class LinkPresenter < PageFieldPresenter
    def rendering(**options)
      div_(options) {[
        pretty_actions,
        a_(href: record.to_url){ title },
      ]}
    end

    def edit_url
      return @edit_url if defined? @edit_url
      @edit_url = record.fieldable.admin_presenter.allowed_url(:edit)
    end
  end
end
