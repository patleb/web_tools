module Admin
  module Sections
    module Index::Search
      extend ActiveSupport::Concern

      OPERATORS = ['=', '!=', '<', '<=', '>', '>=']

      included do
        register_option :filters do
          []
        end

        register_option :advanced_search? do
          true
        end
      end

      def search_menu
        div_('.search_menu', [
          filter_menu,
          query_bar,
          query_helper,
        ])
      end

      def filter_menu
        active_title = false
        title = t('admin.misc.filter')
        scopes = filters.select_map do |filter|
          next unless model.klass.respond_to? filter
          active = (filter = filter.to_s) == params[:f]
          active_title ||= active
          label = t(filter, scope: [model.i18n_scope, :filter, model.i18n_key], default: filter.humanize)
          title = label if active
          [filter, label, active]
        end
        div_('.filter_menu.dropdown.dropdown-end', unless: scopes.empty?) {[
          label_('.filter_title', tabindex: 0, title: (title if active_title), class: ('active' if active_title)) {[
            icon("funnel#{'-fill' if active_title}"),
            span_(title)
          ]},
          ul_('.filter_list.dropdown-content', tabindex: 0) do
            scopes.map do |filter, label, active|
              css_class = "#{filter}_filter"
              if active
                url = model.url(**search_params.except(:f))
                li_(a_ '.active', [label, icon('x-circle')], href: url, class: css_class)
              else
                url = model.url(f: filter, **search_params.except(:f))
                li_(a_ text: label, href: url, class: css_class)
              end
            end
          end
        ]}
      end

      def query_bar
        form_('.query_bar.input-group', action: model.url, method: :get) {[
          search_params.except(:q).map do |name, value|
            input_ name: name, value: value, type: 'hidden'
          end,
          input_('#q.js_search.input',
            type: 'search',
            name: 'q',
            value: params[:q],
            placeholder: t('admin.misc.search'),
            autofocus: true,
            autocomplete: 'off',
            spellcheck: false,
          ),
          button_('.btn.btn-sm.btn-square', icon('search')),
        ]}
      end

      def query_helper
        return unless advanced_search?
        return if (queryable_fields = fields.select(&:queryable?)).empty?
        keywords = [option_(t('admin.misc.operators'), value: '', selected: true, disabled: true)]
        keywords = keywords + t('admin.query').map do |name, label|
          name = "_#{name}"
          option_(name, value: name, title: label)
        end
        operators = [option_(t('admin.misc.keywords'), value: '', selected: true, disabled: true)]
        operators = operators + OPERATORS.map do |value|
          option_(value, value: value)
        end
        div_('.query_helper.swap.collapse') {[
          input_('#query_helper', type: 'checkbox', title: t('admin.misc.advanced_search')),
          div_('.swap-on.collapse-title.btn.btn-circle.btn-xs', ascii(:x)),
          div_('.swap-off.collapse-title.btn.btn-circle.btn-xs', icon('three-dots')),
          div_('.collapse-content.card') do
            div_('.card-body') {[
              div_(select_('.js_query_operator.js_only', operators)),
              div_(select_('.js_query_keyword.js_only', keywords)),
              div_(input_('.js_query_datetime.js_only.input', type: 'date')),
              div_(input_('.js_query_datetime.js_only.input', type: 'time', step: 1)),
              div_([span_('.js_query_or.js_only.btn.btn-circle.btn-xs', '|'), span_(text: 'OR')]),
              div_([span_('.js_query_and.js_only.btn.btn-circle.btn-xs', '{_}'), span_(text: 'AND idem')]),
              queryable_fields.map do |field|
                div_([
                  span_('.js_query_field.js_only.btn.btn-circle.btn-xs', "{#{ascii(:ellipsis)}}", escape: false, data: { field: field.query_name }),
                  span_(field.label)
                ])
              end
            ]}
          end
        ]}
      end

      def query_fields
        fields.each_with_object({}) do |f, hash|
          next unless f.queryable?
          next if (model_param, name, field = f.query_field).empty?
          (hash[model_param] ||= {})[name] = field
        end
      end
    end
  end
end
