# frozen_string_literal: true

module Admin
  module Sections
    class Index < Admin::Section
      autoload :Pagination, include: true
      autoload :Search, include: true

      register_option :description do
        nil
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
        MixAdmin.config.sticky
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
          fields = [id] + fields if id
          fields.first.index_link = true
          fields
        end
      end

      def sort_options(name, reverse = nil)
        field = fields_hash[name.try(:to_sym)] || fields_hash[sort_by]
        name = field.sort_column || "#{model.table_name}.#{sort_by}"
        reverse = field.sort_reverse? if reverse.nil?
        { name: name, reverse: reverse.try(:to_b) }
      end

      def column_name_counts
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
                        id.pretty_index.presence || id.pretty_blank,
                      ]}
                    ]},
                    fields.map do |field|
                      field = field.with(presenter: presenter)
                      td_ '.tooltip', data: { tip: labels[field.name] } do
                        div_('.field_value', field.pretty_index.presence || field.pretty_blank, class: field.css_class, tabindex: 0)
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
