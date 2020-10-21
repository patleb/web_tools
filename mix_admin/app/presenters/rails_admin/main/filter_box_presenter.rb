module RailsAdmin::Main
  class FilterBoxPresenter < ActionPresenter::Base[:@abstract_model]
    delegate :query, to: :index_section

    def query?
      query.present? && queryables.any?
    end

    def render
      return if no_render?
      h_(
        div_('#js_filter_box_init', data: { init: current_filters }),
        form_tag(form_path, method: :get, remote: true, class: "form-inline js_filter_box_form") do
          div_('.well.btn-group.filter_box_actions', { class: ('filter_box_actions_no_query' unless query?) }, [
            div_('#js_filter_box_container'),
            if index_action? || trash_action? || query?
              div_('.input-group', [
                if !bulk_action? && query?
                  query_type = (query == true) ? "search" : query
                  input_ '.js_filter_box_input.form-control.input-sm', name: "query", type: query_type, value: current_query, placeholder: t("admin.misc.filter")
                end,
                if !export_action?
                  span_('.input-group-btn', [
                    if index_action? || trash_action?
                      button_('.filter_box_refresh.btn.btn-primary.btn-sm', { type: 'submit', data: { disable: :submit } }, [
                        i_('.fa.fa-refresh.icon-white'),
                        span_(t('admin.misc.refresh'), class: ('hidden-xs' if query?))
                      ])
                    end,
                    button_('.js_filter_box_clear.btn.btn-info.btn-sm', title: "Reset filters") do
                      i_ '.fa.fa-times.icon-white'
                    end
                  ])
                end
              ])
            end
          ])
        end
      )
    end

    def menu
      return if no_menu?
      li_('#filter_box_options.dropdown.pull-right', { title: (wording = t('admin.misc.add_filter')) }, [
        a_('#js_filter_box_menu.dropdown-toggle', { href: '#', data: { toggle: "dropdown" } }, [
          i_('.fa.fa-search-plus'),
          span_('.hidden-xs', wording),
          b_('.caret')
        ]),
        ul_('.dropdown-menu') do
          filterables.map do |field|
            li_ ".filter_#{field.name}" do
              a_ '.js_filter_box_option', field.label.upcase_first, href: '#', data: { option: filter_options(field) }
            end
          end
        end
      ])
    end

    def no_render?
      (no_menu? && no_box?) || (export_action? && current_filters.empty? && current_query.blank?)
    end

    def no_menu?
      filterables.empty?
    end

    def no_box?
      queryables.empty?
    end

    private

    def filterables
      @_filterables ||= index_fields.select(&:filterable?)
    end

    def queryables
      @_queryables ||= index_fields.select(&:queryable?) # TODO for some reason :created_at and :updated_at always present
    end

    def form_path
      RailsAdmin.url_for(action: main_action, **params.permit(:model_name, :scope, :sort, :reverse).with_keyword_access) # params: ..., anchor: 'js_filter_box_container')
    end

    def current_query
      params[:query]
    end

    def current_filters
      @_current_filters ||= filters.map do |(index, filter_for_field)|
        options = { index: index }
        filter_name, filter_hash = filter_for_field.first
        next unless (field = filterables.find { |f| f.name == filter_name.to_sym })
        case field.type
        when :enum, :sti
          options[:select_options] = options_for_select(field.enum, filter_hash['v'])
        when :date, :datetime, :time
          options[:datetimepicker_format] = field.parser.to_momentjs
        end
        options[:label] = field.label
        options[:name]  = field.name
        options[:type]  = field.type
        options[:value] = filter_hash['v']
        options[:label] = field.label
        options[:operator] = filter_hash['o']
        options
      end.compact
    end

    def filters
      default_index = 0
      (params[:f]&.to_unsafe_h || index_section.filters).each_with_object([]) do |filter, memo|
        case filter
        when Array
          field_name, index_options = filter
        else
          field_name, index_options = filter, { (default_index += 1) => { 'v' => '' } }
        end
        index_options.each do |index, options|
          if options['disabled'].blank?
            memo << [index, { field_name => options }]
          else
            params[:f].delete(field_name)
          end
        end
      end.sort_by(&:first)
    end

    def filter_options(field)
      {
        label: field.label,
        name: field.name,
        options: (%i(enum sti).include?(field.type) ? options_for_select(field.enum) : '').html_safe,
        type: field.type,
        value: "",
        datetimepicker_format: (field.respond_to?(:parser) && field.parser.to_momentjs)
      }
    end
  end
end
