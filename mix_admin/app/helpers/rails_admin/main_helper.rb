module RailsAdmin
  module MainHelper
    def current_action?(action, abstract_model = @abstract_model, object = @object)
      main_action == action.custom_key.to_s \
      && abstract_model&.to_param == @abstract_model&.to_param \
      && (@object&.persisted? ? @object.id == object&.id : !object&.persisted?)
    end

    def wording_for(type, action = @action, abstract_model = @abstract_model)
      model = abstract_model&.model
      object = abstract_model && @object.is_a?(abstract_model.klass) ? @object : nil
      action = RailsAdmin.action(action.to_sym, abstract_model, object) if action.is_a?(Symbol) || action.is_a?(String)

      I18n.t(
        "admin.actions.#{action.i18n_key}.#{type}",
        model_label: model&.label,
        model_label_plural: model&.label_plural,
        object_label: (model.with(object: object).object_label if object),
      ).upcase_first
    end

    def main_navigation
      nodes_stack = RailsAdmin.config.visible_models.stable_sort_by(&:weight)
      model_names = nodes_stack.map{ |m| m.abstract_model.model_name }
      group_nodes = nodes_stack.group_by(&:navigation_parent)

      nodes_stack.group_by(&:navigation_label).html_map do |navigation_label, nodes|
        first_nodes = nodes.select{ |n| n.navigation_parent.nil? || model_names.exclude?(n.navigation_parent) }
        li_stack = main_navigation_stack group_nodes, first_nodes
        navigation_group li_stack, navigation_label
      end
    end

    def main_navigation_stack(group_nodes, nodes, level = 0)
      nodes.html_map do |node|
        next_nodes = group_nodes[node.abstract_model.model_name] || []
        title = node.label_plural.upcase_first
        url = node.abstract_model.url_for(:index)
        h_(
          li_(".js_sidebar_model_#{node.abstract_model.to_param}", title: title) do
            a_('.js_sidebar_model.pjax', { href: url, class: ("nav-level-#{level}" if level > 0) }, [
              if node.navigation_icon
                i_ class: node.navigation_icon
              end,
              title
            ])
          end,
          main_navigation_stack(group_nodes, next_nodes, level + 1)
        )
      end
    end

    def static_navigation
      li_stack = static_navigation_stack
      navigation_group li_stack, t('admin.misc.static_navigation_label')
    end

    def static_navigation_stack
      RailsAdmin.config.navigation_static_links.html_map do |title, url|
        li_ title: title do
          a_ [title, i_('.fa.fa-external-link.sidebar_external')], href: url, target: '_blank'
        end
      end
    end

    def navigation_group(li_stack, label)
      return unless li_stack.present?
      h_(
        li_('.dropdown-header', label.upcase_first),
        li_stack
      )
    end

    # parent => :root, :collection, :member
    def menu_for(abstract_model, object, parent = nil, only_icon = false)
      # TODO add to any menu even if :member or :collection, it's sort of back a button
      parent ||=
        if @abstract_model
          @object&.persisted? ? :member : :collection
        else
          :root # dashboard
        end
      actions = RailsAdmin.actions(parent, abstract_model, object).select do |action|
        action.http_methods.include?(:get) && action.navigable?
      end
      list_inline = (parent == :member && only_icon)
      actions.html_map do |action|
        inline_create, filter_box_shared = false, false
        url =
          if action.key == :new && @model.create.inline?
            inline_create = true
            '#'
          elsif action.key == :show_in_app
            object.to_url
          else
            path_params = {
              action: action.name,
              model_name: abstract_model.to_param,
              id: (object&.id if object&.persisted?)
            }
            if action.searchable?
              filter_box_shared = true
              path_params[:scope] = params[:scope]
            end
            RailsAdmin.url_for(path_params)
          end
        wording = wording_for(:menu, action)
        li_classes = ['icon', "#{action.key}_#{parent}_link"]
        li_classes << 'active' if current_action?(action)
        li_classes << 'js_table_create_link' if inline_create
        li_ title: wording, class: li_classes do
          a_classes = []
          a_classes << 'js_filter_box_shared' if filter_box_shared
          a_classes << 'pjax' if action.pjax?
          a_classes << 'btn btn-default btn-xs' if list_inline
          a_({ href: url, class: a_classes }, [
            i_(class: action.link_icon),
            (span_ '.hidden-xs', wording unless only_icon)
          ])
        end
      end
    end

    def rails_admin_form_for(*args, &block)
      options = args.extract_options!.reverse_merge(builder: FormBuilder)
      options[:html] ||= {}
      # TODO options[:html][:novalidate] = true unless options[:html].has_key?(:novalidate)
      options[:remote] = true unless options.has_key?(:remote)

      # TODO replace with form_with
      form_for(*(args << options), &block) << after_nested_form_callbacks
    end

    def delete_buttons(objects)
      div_('.form-group.form-actions.col-sm-12', [
        hidden_field_tag(:_back, redirect_to_back?),
        button_('.btn.btn-danger', { class: bs_form_row, type: 'submit', data: { disable: :submit } }, [
          i_('.fa.fa-check.icon-white'),
          t('admin.form.delete')
        ]),
        if @model.discardable? && !objects.first.discarded?
          button_('.btn.btn-info', { class: bs_form_row, type: 'submit', name: '_discard', formmethod: :put, data: { disable: :submit } }, [
            i_('.fa.fa-trash'),
            t('admin.form.trash')
          ])
        end,
        button_('.btn', { class: bs_form_row, type: 'submit', name: '_cancel', data: { disable: :submit } }, [
          i_('.fa.fa-times'),
          t('admin.form.cancel')
        ])
      ])
    end

    def bs_form_row
      'input-group col-xs-8 col-sm-6 col-md-4 col-lg-4 bs_form_row'
    end

    # TODO move to ExtRails
    def after_nested_form(association, &block)
      @nested_form_associations ||= {}
      @nested_form_callbacks ||= []
      unless @nested_form_associations[association]
        @nested_form_associations[association] = true
        @nested_form_callbacks << block
      end
    end

    private

    def after_nested_form_callbacks
      @nested_form_callbacks ||= []
      fields = []
      while (callback = @nested_form_callbacks.shift)
        fields << callback.call
      end
      fields.join.html_safe
    end
  end
end
