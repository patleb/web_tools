class PageFieldPresenter < ActionPresenter::Base[:@page]
  LINK_ICONS = {
    edit:   'fa fa-pencil',
    delete: 'fa fa-trash-o fa-fw'
  }

  attr_accessor :list, :parent_node, :parent_name
  attr_writer   :level, :children_count

  delegate :id, :name, :type, :position, :parent_id, to: :object

  def viable_parent_names
    []
  end

  def node_name
    nil
  end

  def level
    @level || 0
  end

  def children_count
    @children_count || 0
  end

  def last?
    children_count == 0
  end

  def close?
    children_count > MixPage.config.max_children_count
  end

  def dom_class
    ["presenter_#{name}", super(object), 'page_field'].uniq
  end

  def html_list_options
    data = { node: (node_name || :_unrelated), close: close? }
    return { data: data } unless list && editable?
    {
      class: ['js_page_field_item'],
      data: data.merge!(id: id, parent: (parent_name || :_unrelated), level: level, last: last?)
    }
  end

  def html_options
    { class: dom_class }
  end

  def html(**)
    raise NotImplementedError
  end

  def render(**item_options, &block)
    html(html_options.with_keyword_access.union!(item_options), &block)
  end

  def editable
    member_actions[:edit]
  end
  alias_method :editable?, :editable

  def pretty_blank
    I18n.t('page_fields.edit', model: object.model_name.human.downcase) if editable?
  end

  def pretty_actions(tag = :div)
    with_tag(tag, '.page_field_actions', if: member_actions.any?) {[
      sort_action,
      member_actions.map do |action, path|
        button_(class: "#{action}_page_field #{action}_#{type.full_underscore} btn btn-default btn-xs", data: { href: path }) do
          i_(class: LINK_ICONS[action])
        end
      end
    ]}
  end

  def sort_action
    return unless list && editable? && last? && (parent_node.nil? || parent_node.children_count > 1)
    span_(class: "js_page_field_sort sort_page_field sort_#{type.full_underscore}") do
      i_(class: 'fa fa-arrows-v')
    end
  end

  def member_actions
    @member_actions ||= MixPage.config.member_actions.each_with_object({}) do |action, all|
      path = !Current.user_role? && admin_path_for(action, object, _back: true)
      all[action] = path if path
    end
  end

  def sync_position(previous_node)
    if (previous_position = previous_node&.position)
      if previous_position > position
        object.update! list_prev_id: previous_node.object.id
      end
    end
  end
end
