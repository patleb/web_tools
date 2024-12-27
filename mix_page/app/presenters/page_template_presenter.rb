# frozen_string_literal: true

class PageTemplatePresenter < ActivePresenter::Base
  delegate :title, to: :record

  def dom_class
    ['page']
  end

  def html_options
    { class: dom_class }
  end

  def render(tag: 'h1', **options)
    options = html_options.to_hwka.union!(options)
    div_(options) {[
      with_tag(tag, '.page_actions', [
        edit_action,
        title.presence || pretty_blank,
      ]),
      yield,
    ]}
  end

  def pretty_blank
    t('page_template.edit', model: record.class.admin_label) if can_update?
  end

  def can_update?
    edit_url
  end

  def edit_action
    return unless can_update?
    tooltip = t('page_template.edit', model: record.class.admin_label)
    a_('.page_edit', href: edit_url, title: tooltip) do
      icon('pencil-square')
    end
  end

  def edit_url
    return @edit_url if defined? @edit_url
    @edit_url = record.admin_presenter.allowed_url(:edit)
  end
end
