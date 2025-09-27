module AdminHelper
  def admin_user_link
    return unless admin_user_link?
    li_ do
      a_ '.admin_user_link', [icon('person'), Current.user.email], href: Current.user.admin_presenter.viewable_url
    end
  end

  def admin_user_link?
    Current.logged_in? && Current.user.admin_presenter.viewable?
  end

  def admin_link
    return unless admin_link?
    li_ do
      a_ '.admin_link.admin_root', [icon('layout-text-window-reverse'), t('link.admin')], href: admin_root_path
    end
  end

  def admin_link?
    Current.logged_in? && !Current.controller.is_a?(AdminController)
  end

  def app_link(**options)
    return unless app_link?
    li_ do
      a_ '.admin_link.app_root', [icon('eye'), t('link.app')], href: application_path, **options
    end
  end

  def app_link?
    !Current.controller.is_a?(ApplicationController)
  end

  def admin_flash(key)
    flash_message(key, scope: :admin)
  end

  def admin_flash_search(messages)
    [t('admin.search.title')].concat(messages.map do |(error, statement)|
      "#{t(error, scope: 'admin.search.error')}: #{ERB::Util.html_escape(statement)}"
    end).join(ExtRails::ERROR_SEPARATOR).html_safe
  end

  def admin_actions_menu
    object = action_object
    actions = Admin::Action.all("#{action_type}?").select(&:navigable?)
    actions.prepend Admin::Action.find_class(:index) if (back_to_index = (action_type == :member))
    nav_('.nav_actions.tabs',
      actions.map do |action|
        name = action.key
        search = action.searchable_tab? && search_params || {}
        active = name == @action.name
        title = action.title(:menu, object)
        url = if back_to_index && name == :index
          object.model.allowed_url(name, **search)
        elsif object
          object.allowed_url(name, **search)
        else
          MixAdmin::Routes.url_for(action: name)
        end
        a_('.nav_action.tab.tab-bordered', href: url, class: ('tab-active' if active), if: url) {[
          icon(action.icon, class: [action.css_class, 'md-1:tooltip', 'md-1:tooltip-bottom'], data: { tip: title }),
          span_(title)
        ]}
      end
    )
  end

  def admin_sidebar
    [
      ul_(admin_models_menu),
      ul_(admin_root_menu),
      ul_(admin_static_menu, if: Current.user.admin?),
    ]
  end

  def admin_models_menu
    if MixAdmin.config.memoize_models_menu
      menu = ((@@admin_models_menu ||= {})[Current.locale] ||= {})[Current.user.as_role] ||= _admin_models_menu
      menu.sub(/\{active:#{@model&.model_name}\}/, '').html_safe
    else
      _admin_models_menu
    end
  end

  def admin_root_menu
    actions = Admin::Action.all(:root?).select(&:navigable?)
    return if actions.empty?
    [ li_('.menu_divider'),
      li_('.menu-title', span_(t('admin.misc.root_navigation_label'))),
    ].concat(actions.map! do |action|
      title = action.title(:menu)
      li_ do
        a_ [icon(action.icon), title], href: MixAdmin::Routes.url_for(action: action.key)
      end
    end)
  end

  def admin_static_menu
    li_stack = MixAdmin.config.navigation_static_links.html_map do |title, url|
      li_ do
        a_ [title, icon('box-arrow-up-right')], href: url, target: '_blank'
      end
    end
    _admin_menu_stack li_stack, t('admin.misc.static_navigation_label')
  end

  private

  def _admin_models_menu
    nodes_stack = Admin::Model.index_models.stable_sort_by(&:weight)
    model_names = nodes_stack.map(&:model_name)
    parent_nodes = nodes_stack.group_by(&:navigation_parent)
    nodes_stack.group_by(&:navigation_group).html_map do |navigation_group, nodes|
      first_nodes = nodes.select{ |n| n.navigation_parent.nil? || model_names.exclude?(n.navigation_parent) }
      li_stack = _admin_models_menu_stack parent_nodes, first_nodes
      _admin_menu_stack li_stack, navigation_group
    end || ''.html_safe
  end

  def _admin_models_menu_stack(parent_nodes, nodes, level = 0)
    nodes.html_map do |node|
      next_nodes = parent_nodes[node.model_name] || []
      link_icon = node.navigation_icon
      title = node.label_plural.upcase_first
      url = node.url_for(:index)
      h_(
        li_(class: "bordered{active:#{node.model_name}}") do
          steps = [ascii(:space, times: level - 1), ascii_(:arrow_down_right)] if level > 0
          a_ [steps, (icon(link_icon) if link_icon), title], href: url
        end,
        _admin_models_menu_stack(parent_nodes, next_nodes, level + 1)
      )
    end
  end

  def _admin_menu_stack(li_stack, label)
    return unless li_stack.present?
    h_(
      li_('.menu_divider'),
      li_('.menu-title', span_(label.upcase_first)),
      li_stack
    )
  end
end
