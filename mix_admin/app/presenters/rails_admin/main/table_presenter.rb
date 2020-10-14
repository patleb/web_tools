module RailsAdmin::Main
  class TablePresenter < ActionPresenter::Base[:@model, :@abstract_model]
    delegate :dynamic_columns?, to: :index_section

    def description
      @_description ||= @model.description
    end

    def options
      {
        class: ["#{@abstract_model.param_key}_list", ('no_bulk_menu' if bulk.no_menu?)],
        data: { name: @abstract_model.param_key }
      }
    end

    def head_options(field, i)
      if !sort_action? && field.sortable
        selected = (sort == field.name.to_s)
        path_params = params.merge(sort: field.name)
        if selected
          path_params[:reverse] = true unless reverse
          sort_direction = (reverse ? "js_table_sort_down" : "js_table_sort_up")
        end
        sort_location = RailsAdmin.url_for(action: main_action, **path_params.with_keyword_access)
        sortable_css = 'pjax'
      end
      if i == 0
        frozen_column = 'js_table_frozen_column' if index_section.frozen_column?
      else
        move_column = 'js_table_move_column' if !trash_action? && dynamic_columns? && field.dynamic_column?
      end
      {
        class: [field.css_classes(:table_head), frozen_column, move_column, sortable_css, sort_direction],
        data: { name: field.name, href: sort_location }
      }
    end

    def row_options(object)
      {
        class: ["#{@abstract_model.param_key}_row", index_section.with(object: object).row_css_class],
        data: { name: @abstract_model.param_key }
      }
    end

    def body_options(field, i)
      if i == 0
        frozen_column = 'js_table_frozen_column' if index_section.frozen_column?
      end
      { class: [field.css_classes(:table), frozen_column], data: { name: field.name } }
    end

    def inline_create
      return unless @model.create.inline? && !request.variant.more?

      model_name = @abstract_model.param_key
      create_fields = @model.create.visible_fields
      create_fields = fields.map do |field|
        if (i = create_fields.find_index{|f| f.name == field.name})
          create_fields[i].inline_create = true
          create_fields[i]
        else
          field
        end
      end

      tr_('.js_table_create_row', [
        td_ do
          a_ '.btn.btn-default.btn-xs.js_table_create_cancel' do
            i_ '.fa.fa-trash-o.fa-fw'
          end
        end,
        create_fields.map do |field|
          if field.inline_create && !field.readonly?
            name_attr = "#{model_name}[#{field.name}]"
            value_attr = field.form_value
            props = [name_attr, nil]
            props << value_attr.to_b if field.type == :boolean
            html_attr = field.html_attributes.reverse_merge(required: field.required, value: value_attr)
            td_ class: field.css_classes(:table_create) do
              send "#{field.view_helper}_tag", *props, html_attr
            end
          else
            td_ class: field.css_classes(:table) do
              field.pretty_blank
            end
          end
        end,
        td_('.table_row_actions') do
          ul_ do
            li_ do
              a_ '.btn.btn-primary.btn-xs.js_table_create_save' do
                i_ '.fa.fa-check.icon-white'
              end
            end
          end
        end
      ])
    end

    def inline_update(object, field)
      model_name, id, name = object.model_name.admin_param_key, object.id, field.name

      name_attr = "#{model_name}[#{field.name}]"
      value_attr = field.form_value
      props = [name_attr, nil]
      props << value_attr.to_b if field.type == :boolean
      html_attr = field.html_attributes.reverse_merge(id: "#{id}_#{name}", required: field.required, value: value_attr, readonly: true)

      td_ class: field.css_classes(:table_update) do
        send "#{field.view_helper}_tag", *props, html_attr
      end
    end

    def fields
      @_fields ||= begin
        fields, moved = [], []
        index_fields.select(&:index_visible?).each do |field|
          next if removed_columns[field.name]
          if (index = moved_columns[field.name])
            moved << [index, field]
          else
            fields << field
          end
        end
        max = fields.size + moved.size
        moved.sort_by!(&:first).each do |(index, field)|
          break fields << nil unless 0 < index && index < max
          fields.insert(index, field)
        end
        if fields.any?(&:nil?) # out of sync
          clear_model_cookie
          fields = []
        end
        if (i = fields.index{ |field| field.is_a? RailsAdmin::Config::Model::Fields::Discarded })
          fields << fields.delete_at(i)
        end
        fields
      end
    end

    private

    def moved_columns
      @_moved_columns ||= model_cookie[:move] || {}
    end

    def removed_columns
      @_removed_columns ||= model_cookie[:remove] || {}
    end
  end
end
