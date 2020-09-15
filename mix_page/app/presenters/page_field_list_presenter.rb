class PageFieldListPresenter < ActionPresenter::Base[:@page, :@virtual_path]
  delegate :name, to: 'list.first.object'

  def after_initialize
    list.each{ |presenter| presenter.list = self }
  end

  def render(&block)
    ul_(class: [('js_page_field_list' if editable_items.any?), "#{name}_presenter", dom_class]) {[
      list.map do |presenter|
        id = presenter.object.id
        li_('.js_page_field_item', class: presenter.dom_class, data: { id: (id if editable_items.has_key? id) }) do
          presenter.render(&block)
        end
      end,
      li_('.collection_types', if: collection_types.any?) do
        ul_('.new_object') do
          collection_types.map do |type|
            li_(".new_#{type.full_underscore}") do
              form_tag(page_field_path(uuid: @page.uuid), method: :post) {[
                input_(name: "page_field[type]", type: "hidden", value: type),
                input_(name: "page_field[name]", type: "hidden", value: name),
                input_(name: "page_field[page_id]", type: "hidden", value: page_id),
                button_(type: 'submit'){ "New #{type}" }
              ]}
            end
          end
        end
      end
    ]}
  end

  def dom_class
    [self.class.name.full_underscore.delete_suffix('_presenter'), 'page_field_list'].uniq
  end

  def editable_items
    @editable_items ||= list.map{ |presenter| [presenter.object.id, can?(:edit, presenter.object)] }.to_h.compact
  end

  def collection_types
    @collection_types ||= (type ? [type] : MixPage.config.available_fields.keys).select{ |type| can? :create, type }
  end
end
