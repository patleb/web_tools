# frozen_string_literal: true

class PageFieldListPresenter < ActivePresenter::List[:@page]
  delegate :type, :name, to: 'list.first.record'

  def dom_class
    [ 'field_list',
      "field_#{name.full_underscore}_list",
      "field_#{type.demodulize.underscore}_list",
    ]
  end

  def html_options
    { class: dom_class }
  end

  def list_options
    list.any?(&:can_update?) ? { class: ['js_page_field_list'] } : {}
  end

  def rendering(list_tag: 'div', item_tag: 'div', item_options: {}, divider: false, **options)
    with_tag(list_tag, options) {[
      with_tag(item_tag, '.menu_divider', if: divider),
      list.map.with_index(1) do |presenter, i|
        with_tag(item_tag, presenter.item_options) do
          presenter.render(**item_options, i: i)
        end
      end,
      with_tag(item_tag, if: can_create?){ new_action },
    ]}
  end

  def render(**options, &block)
    options = html_options.to_hwka.union!(list_options).union! options
    if block_given?
      instance_exec(**options, &block)
    else
      rendering(**options)
    end
  end

  def can_create?
    can?(:new, type) && name.end_with?('s')
  end

  def new_action
    return unless can_create?
    a_ '.field_new', icon('plus-circle'),
      title: t('page_fields.new'),
      href: MixPage::Routes.new_page_field_path(uuid: @page.uuid),
      remote: true,
      visit: true,
      method: 'post',
      params: { page: { field: { type: type, name: name } } }
  end
end
