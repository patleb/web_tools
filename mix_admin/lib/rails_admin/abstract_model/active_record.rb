require_rel 'active_record'

module RailsAdmin
  module AbstractModel::ActiveRecord
    DISABLED_COLUMN_TYPES = [:tsvector, :blob, :binary, :spatial, :hstore, :geometry].freeze

    delegate :primary_key, :table_name, to: :klass

    def new(params = {})
      if klass.respond_to? :new_with_defaults
        klass.new_with_defaults(params)
      else
        klass.new(params)
      end
    end

    # TODO klass.select(*columns).where...
    def get(id)
      klass.where(primary_key => id).take
    end

    def scoped
      klass.all
    end

    def all(scope = nil, **options)
      scope ||= scoped
      scope = scope.includes(options[:include]) if options[:include]
      scope = scope.left_joins(options[:left_join]) if options[:left_join]
      scope = bulkable_scope(scope, options[:bulk_ids]) if options[:bulk_ids]
      scope = query_scope(scope, options[:query]) if options[:query]
      scope = filters_scope(scope, options[:filters]) if options[:filters]
      scope = sort_scope(scope, options[:sort], options[:reverse]) if options[:sort]
      scope = page_scope(scope, **options) if options[:page]
      scope = scope.distinct if options[:distinct]
      scope
    end

    def associations
      klass.reflect_on_all_associations.map do |association|
        Association.new(association, klass)
      end
    end

    def columns
      columns = klass.columns.reject do |c|
        c.type.blank? || DISABLED_COLUMN_TYPES.include?(c.type.to_sym)
      end
      columns.map do |column|
        Column.new(column, klass)
      end
    end

    def bulkable_scope(scope, bulk_ids)
      if model.discardable?
        bulkables = RailsAdmin.actions(:bulkable_trash, self).map(&:main_name)
        scope = scope.with_discarded if Current.controller.main_action.in? bulkables
      end
      scope.where(primary_key => bulk_ids)
    end

    def query_scope(scope, query)
      fields = model.index.fields.select(&:queryable?)
      wb = WhereBuilder.new(scope)
      fields.each do |field|
        value = parse_field_value(field, query)
        wb.add(field, value, field.search_operator)
      end
      # OR all query statements
      wb.build
    end

    # filters example => {"string_field"=>{"0055"=>{"o"=>"like", "v"=>"test_value"}}, ...}
    # "0055" is the filter index, no use here. o is the operator, v the value
    def filters_scope(scope, filters)
      fields = model.index.fields.select(&:filterable?)
      filters.each_pair do |field_name, filters_dump|
        filters_dump.each do |_, filter_dump|
          wb = WhereBuilder.new(scope)
          field = fields.find{ |f| f.name == field_name.to_sym }
          value = parse_field_value(field, filter_dump[:v])

          wb.add(field, value, (filter_dump[:o] || 'default'))
          # AND current filter statements to other filter statements
          scope = wb.build
        end
      end
      scope
    end

    def sort_scope(scope, sort, reverse)
      scope = scope.reorder(sort.sql_safe)
      scope = scope.reverse_order if reverse
      scope
    end

    def page_scope(scope, page:, per:, first:, sort:, reverse:, **)
      scope = scope.where("#{sort} #{reverse ? '<=' : '>='} ?", first) if page > 1 && first
      scope = scope.page(page).per(per)
      scope = scope.without_count if model.index.limited_pagination?
      scope
    end
  end
end
