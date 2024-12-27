# frozen_string_literal: true

class PageFieldPresenter < ActivePresenter::Base[:@page]
  delegate :type, :name, to: :record

  attr_reader :position

  def dom_class
    [ 'field',
      "field_#{name.full_underscore}",
      "field_#{type.demodulize.underscore}"
    ]
  end

  def html_options
    { class: dom_class }
  end

  def item_options
    sortable? ? { class: ['js_page_field'], data: { id: record.id } } : {}
  end

  def rendering(**)
    raise NotImplementedError
  end

  def render(i: nil, **options, &block)
    options = html_options.to_hwka.union! options
    @position = i
    if block_given?
      instance_exec(**options, &block)
    else
      rendering(**options)
    end
  end

  def pretty_blank
    t('page_fields.edit', model: record.class.admin_label).downcase.upcase_first if can_update?
  end

  def pretty_actions
    div_('.field_actions', if: can_update?) {[
      sort_action,
      edit_action,
    ]}
  end

  def can_update?
    edit_url
  end

  def sortable?
    list && can_update?
  end

  def sort_action
    return unless sortable?
    span_ '.js_page_field_sort', ascii(:arrow_y)
  end

  def edit_action
    a_('.field_edit', icon('pencil-square'), href: edit_url)
  end

  def edit_url
    return @edit_url if defined? @edit_url
    @edit_url = record.admin_presenter.allowed_url(:edit)
  end
end
