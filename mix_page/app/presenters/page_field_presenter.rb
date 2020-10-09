class PageFieldPresenter < ActionPresenter::Base[:@page]
  LINK_ICONS = {
    sort:   'fa fa-arrows-v',
    edit:   'fa fa-pencil',
    delete: 'fa fa-trash-o fa-fw'
  }

  attr_accessor :list
  attr_writer   :level, :last

  delegate :i18n_scope, to: :class
  delegate :id, :name, :type, to: :object

  def self.i18n_scope
    @i18n_scope ||= [:page_fields, :presenter]
  end

  def level
    @level || 0
  end

  def last?
    @last || false
  end

  def parent_name
    nil
  end

  def node_name
    :_unrelated
  end

  def dom_class
    ["presenter_#{name}", super(object), "page_field"].uniq
  end

  def html_list_options
    return {} unless list && editable
    {
      class: ["js_page_field_item"],
      data: { id: id, level: level, last: last?, parent: parent_name || :_unrelated, node: node_name }
    }
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
    member_actions[:edit]
  end
  alias_method :editable?, :editable

  def pretty_blank
    return '' unless editable?
    I18n.t('page_fields.edit', model: object.model_name.human.downcase)
  end

  def pretty_actions(tag = :div)
    return '' unless member_actions.any?
    with_tag(tag, '.page_field_actions') {[
      sort_action,
      member_actions.map do |action, path|
        button_(class: "#{action}_page_field #{action}_#{type.full_underscore} btn btn-default btn-xs", data: { href: path }) do
          i_(class: LINK_ICONS[action])
        end
      end
    ]}
  end

  def sort_action
    return unless list && editable?
    span_(class: "js_page_field_sort sort_page_field sort_#{type.full_underscore}") do
      i_(class: LINK_ICONS[:sort])
    end
  end

  def member_actions
    @member_actions ||= {
      edit:   !Current.user_role? && admin_path_for(:edit, object, _back: true),
      delete: !Current.user_role? && admin_path_for(:delete, object, _back: true),
    }.reject{ |_, v| v.blank? }
  end
end
