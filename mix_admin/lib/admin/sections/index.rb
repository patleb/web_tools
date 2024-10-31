# frozen_string_literal: true

module Admin
  module Sections
    class Index < Admin::Section
      autoload :Paginate, include: true

      OPERATORS = ['=', '!=', '<', '<=', '>', '>=']

      register_option :description do
        nil
      end

      register_option :filters do
        []
      end

      register_option :advanced_search? do
        true
      end

      register_option :exists? do
        true
      end

      alias_method :exists_without_scope?, :exists?
      def exists?(scope = nil)
        @scope = scope
        exists_without_scope?
      ensure
        remove_ivar(:@scope)
      end

      def filtered?(scope)
        scope.values[:where].send(:predicates).size > 1
      end

      register_option :sort_by do
        if model.columns_hash.has_key? :updated_at
          :updated_at
        else
          model.primary_key.to_sym
        end
      end

      register_option :sticky? do
        MixAdmin.config.sticky?
      end

      def fields
        memoize(self, __method__, bindings) do
          id = nil
          fields = super.each_with_object([]) do |field, all|
            if field.primary_key?
              id = field
            else
              all << field
            end
          end
          raise "#{model_name} presenter doesn't have a primary key configured" unless id
          [id] + fields
        end
      end

      def sort_options(name, reverse = nil)
        field = fields_hash[name.try(:to_sym)] || fields_hash[sort_by]
        name = field.sort_column || "#{model.table_name}.#{sort_by}"
        reverse = field.sort_reverse? if reverse.nil?
        { name: name, reverse: reverse.try(:to_b) }
      end

      def render
        labels = {}
        id, *fields = self.fields
        h_(
          div_('.model_info.dropdown', if: description.present?) {[
            div_('.card.dropdown-content', tabindex: 0) do
              div_('.card-body', [
                p_{ description },
              ])
            end,
            label_('.btn.btn-circle.btn-xs', icon('info-circle'), tabindex: 0, title: t('admin.misc.description')),
          ]},
          form_('.js_bulk_form.table_wrapper', **bulk_form_options) {[
            table_([
              thead_('.js_table_head') do
                tr_([
                  th_(class: ('sticky' if sticky?)) {[
                    input_('.js_bulk_toggles.js_only.checkbox', type: 'checkbox', disabled: !bulk_items?),
                    span_(labels[id.name] = id.label),
                    id.sort_link,
                  ]},
                  fields.map do |field|
                    th_([
                      span_(labels[field.name] = field.label),
                      field.sort_link,
                    ])
                  end
                ])
              end,
              tbody_('.js_table_body') {[
                presenters.map do |presenter|
                  id = id.with(presenter: presenter)
                  tr_([
                    th_(class: ('sticky' if sticky?)) {[
                      input_('.js_bulk_checkboxes.checkbox', type: 'checkbox', name: 'ids[]', value: id.value, disabled: !bulk_items?),
                      span_('.field_value', class: id.css_class) {[
                        inline_menu(presenter),
                        id.index_value,
                      ]}
                    ]},
                    fields.map do |field|
                      field = field.with(presenter: presenter)
                      td_ '.tooltip', data: { tip: labels[field.name] } do
                        span_('.field_value', field.index_value, class: field.css_class, tabindex: 0)
                      end
                    end
                  ])
                end,
                tr_([
                  th_(class: ('sticky' if sticky?)) do
                    bulk_menu
                  end,
                  th_(colspan: fields.size),
                ]),
              ]},
            ]),
          ]},
          pagination,
        )
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

      def query_column_names_counts
        memoize(self, __method__, bindings) do
          models = Set.new
          fields.each_with_object({}) do |field, hash|
            next if !field.queryable? || field.association? && !field.eager_load
            model = field.property_model
            models.include?(model) ? next : models << model
            model.columns_hash.each do |name, column|
              next if column.virtual?
              hash[name] ||= 0
              hash[name] += 1
            end
          end
        end
      end

      def bulk_form_options
        { method: :get }
      end

      def bulk_menu
        div_('.bulk_menu.dropdown.dropdown-right.dropdown-end', if: bulk_items?) {[
          label_('.bulk_title', icon('check2-square'), tabindex: 0, title: t('admin.misc.bulk_menu_title')),
          ul_('.bulk_list.dropdown-content', bulk_items, tabindex: 0)
        ]}
      end

      def bulk_items?
        !bulk_items.empty? && !presenters.empty?
      end

      def bulk_items
        memoize(self, __method__, bindings) do
          Admin::Action.all(:bulkable?).select_map do |action|
            name = action.key
            next unless (url = model.allowed_url(name))
            options = {}
            options.merge! name: "_#{name}", value: self.action.name, data: confirm(name) if self.action.trashable?
            li_(
              button_ '.js_bulk_buttons', action.title(:bulk_link), formaction: url, class: action.css_class, **options
            )
          end
        end
      end

      def inline_menu?(presenter)
        !inline_items(presenter).empty?
      end

      def inline_menu(presenter)
        return unless inline_menu? presenter
        div_('.inline_menu.dropdown.dropdown-right.dropdown-end') {[
          label_(icon('three-dots-vertical'), tabindex: 0),
          ul_('.dropdown-content', inline_items(presenter), tabindex: 0),
        ]}
      end

      def inline_items(presenter)
        memoize(self, __method__, bindings, presenter) do
          Admin::Action.all(:member?).select_map do |action|
            url = presenter.allowed_url(action.key)
            li_(a_ text: action.title(:menu, presenter), href: url, class: action.css_class) if url
          end
        end
      end
    end
  end
end
