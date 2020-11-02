module PageFields
  class LinkListPresenter < PageFieldListPresenter
    def render(list_options = {}, item_options = {})
      if list_options.delete(:sidebar)
        super do |list, options, actions|
          ul_(options.union(class: ['nav nav-pills nav-stacked', ('sidebar_foldable' if foldable?)])) {[
            li_('.dropdown-header', t("page_sidebar.#{name}")),
            list.map do |presenter|
              li_(presenter.html_list_options) do
                presenter.render(sidebar: true)
              end
            end,
            li_ do
              actions
            end
          ]}
        end
      else
        super
      end
    end

    def foldable?
      list.any?(&:foldable?)
    end
  end
end
