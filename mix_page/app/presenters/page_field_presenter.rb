class PageFieldPresenter < ActionPresenter::Base[:@page]
  LINK_ICONS = {
    edit:   'fa fa-pencil',
    delete: 'fa fa-trash-o fa-fw'
  }

  attr_accessor :list

  delegate :i18n_scope, to: :class
  delegate :id, :name, :type, to: :object

  def self.i18n_scope
    @i18n_scope ||= [:page_fields, :presenter]
  end

  def dom_class
    ["#{name}_presenter", super(object), "page_field"].uniq
  end

  def html_list_options
    editable ? { class: ['js_page_field_item'], data: { id: id } } : {}
  end

  def html_options
    { class: dom_class }
  end

  def html(**)
    raise NotImplementedError
  end

  def render(**item_options)
    html(html_options.with_keyword_access.union!(item_options))
  end

  def editable
    return @editable if defined? @editable
    @editable = can?(:edit, object)
  end
  alias_method :editable?, :editable

  def pretty_blank
    return '' unless editable?
    I18n.t('page_fields.edit', model: object.model_name.human.downcase)
  end

  def pretty_actions(tag = :div)
    return '' unless member_actions.any?
    with_tag(tag, '.page_field_actions') do
      member_actions.map do |action, path|
        button_(class: "#{action}_page_field #{action}_#{type.full_underscore} btn btn-default btn-xs", data: { href: path }) do
          i_(class: LINK_ICONS[action])
        end
      end
    end
  end

  def member_actions
    @member_actions ||= {
      edit:   admin_path_for(:edit, object, _back: true),
      delete: admin_path_for(:delete, object, _back: true),
    }.compact
  end
end
