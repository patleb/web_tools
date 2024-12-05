# frozen_string_literal: true

class PageFieldPresenter < ActivePresenter::Base[:@page]
  delegate :type, :name, to: :record

  attr_reader :new_action, :position

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

  def render(new_action: nil, i: nil, **options)
    @new_action, @position = new_action, i
    options = html_options.with_indifferent_access.union! options
    yield(options, pretty_actions)
  end

  def pretty_blank
    t('page_fields.edit', model: record.class.admin_label).downcase.upcase_first if can_update?
  end

  def pretty_actions
    div_('.field_actions', if: can_update?) {[
      sort_action,
      (ascii(:space, times: 3) if sortable?),
      edit_action,
      (ascii(:space, times: 3) if can_create?),
      new_action,
    ]}
  end

  def can_create?
    new_action
  end

  def can_update?
    return @edit_url if defined? @edit_url
    @edit_url = edit_url
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
    record.admin_presenter.allowed_url(:edit)
  end
end
