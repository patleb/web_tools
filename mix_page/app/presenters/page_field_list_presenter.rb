class PageFieldListPresenter < ActionPresenter::Base[:@page]
  delegate :name, to: 'list.first.object'

  def after_initialize
    list.each{ |presenter| presenter.list = self }
  end

  def dom_class
    ["presenters_#{name}", self.class.name.full_underscore.delete_suffix('_presenter'), "page_field_list"].uniq
  end

  def html_list_options
    list.select(&:editable?).any? ? { class: ['js_page_field_list'] } : {}
  end

  def html_options
    { class: dom_class }
  end

  def render(list_options = {}, item_options = {})
    list_options = html_options.with_keyword_access.union!(html_list_options).union!(list_options)
    if block_given?
      yield(list, list_options, pretty_actions)
    else
      div_(list_options) {[
        list.map do |presenter|
          div_(presenter.html_list_options) do
            presenter.render(item_options)
          end
        end,
        pretty_actions
      ]}
    end
  end

  def pretty_actions
    div_('.dropup.page_field_list_actions') {[
      button_('.btn.btn-default.btn-xs.dropdown-toggle', type: 'button', data: { toggle: 'dropdown' }, aria: { haspopup: true, expanded: false }) {[
        i_(class: 'fa fa-plus'),
        span_('.hidden-xs', I18n.t('page_fields.new')),
      ]},
      ul_('.dropdown-menu') do
        types.map do |type|
          li_(".new_page_field.new_#{type.full_underscore}") do
            a_(href: field_path, data: { method: :post, params: { page_field: { type: type, name: name, page_id: page_id } } }) do
              type.to_const.model_name.human
            end
          end
        end
      end
    ]}
  end

  def field_path
    @field_path ||= page_field_path(uuid: @page.uuid)
  end
end
