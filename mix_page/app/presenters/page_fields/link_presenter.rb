module PageFields
  class LinkPresenter < PageFieldPresenter
    def item_options
      options = super
      options.union!({ class: ['bordered', 'tab-active'] }) if request.path.start_with? record_url
      options
    end

    def rendering(**options)
      div_(options) {[
        pretty_actions,
        a_(href: record_url){ title },
      ]}
    end

    def edit_url
      return @edit_url if defined? @edit_url
      @edit_url = record.fieldable.admin_presenter.allowed_url(:edit)
    end

    def record_url
      return @record_url if defined? @record_url
      @record_url = record.to_url
    end
  end
end
