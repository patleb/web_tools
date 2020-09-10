class PageFieldListPresenter < ActionPresenter::Base[:@page, :@virtual_path]
  delegate :key, to: 'list.first.object'

  def after_initialize
    list.each{ |presenter| presenter.list = self }
  end

  def render(&block)
    ul_('.js_page_field_list', class: ["#{key}_presenter", dom_class]) {[
      list.map do |presenter|
        id = presenter.object.id if Current.user.admin?
        li_('.js_page_field_item', class: presenter.dom_class, data: { id: id }) do
          presenter.render(&block)
        end
      end,
      li_('.collection_actions', if: Current.user.admin?) do
        ul_ do
          available_types.map do |type|
            li_('.new_object') do
              form_tag(page_field_path(uuid: @page.uuid), method: :post) {[
                input_(name: "page_field[type]", type: "hidden", value: type),
                input_(name: "page_field[page_id]", type: "hidden", value: page_id),
                input_(name: "page_field[key]", type: "hidden", value: key),
                button_(type: 'submit'){ "new #{type}" }
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

  def id_at(i)
    list[i]&.object&.id
  end

  def available_types
    @available_types ||= (type ? [type] : MixPage.config.available_fields.keys).select do |type|
      can?(:new, type)
    end
  end
end
