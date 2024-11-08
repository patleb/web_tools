# frozen_string_literal: true

module Admin::Model::Searchable
  STATEMENTS = /\s(?=(?:[^"]|"[^"]*")*$)/
  SPACE = '[:space:]'
  COMMA = '[:comma:]'
  QUOTE = '[:quote:]'
  QUOTED_STRING = /^".*"$/
  QUOTES = /(^"\s*|\s*"$)/
  SINGLE_QUOTED_STRING = /^'.*'$/
  SINGLE_QUOTES = /(^'\s*|\s*'$)/
  NAME = /[a-z][a-z_0-9]*/
  FIELD = /(_|#{NAME}(?:-#{NAME})*)(?:\.(#{NAME}))?/
  IDEM = '{_}'
  BRACES = /(^\{|}$)/
  OPERATOR = /[=!<>]=?/
  TIME = /[0-9]{2}:[0-9]{2}(:[0-9]{2})?/
  DATETIME = /^([0-9]{4}-[0-9]{2}-[0-9]{2}(T#{TIME})?|#{TIME})$/
  BOOLEAN = /^_(true|false)$/i
  OR = /\|/
  IN = /,/
  EQUAL = '='
  NOT_EQUAL = '!='

  def get(scope, section, ids: nil, id: nil)
    scope = select_columns(scope, section)
    ids ? scope.find(ids) : [scope.find(id)]
  end

  def count(scope, section, **options)
    scope = search(scope, section, **options, all: true)
    section.try(:countless) ? scope.count_estimate : scope.size
  end

  def search(scope, section, q: nil, f: nil, s: nil, r: nil, all: false)
    associations = section.fields.select(&:association?)
    eager_load = associations.select_map(&:eager_load).uniq
    left_joins = associations.select_map(&:left_joins).uniq
    sort_options = section.sort_options(s, r)
    scope = select_columns(scope, section)
    scope = scope.public_send(f) if section.filters.any?{ |filter| filter.to_s == f }
    scope = scope.includes(eager_load) unless eager_load.empty?
    scope = scope.left_joins(left_joins) unless left_joins.empty?
    scope, errors = query_scope(scope, section, q)
    if errors.empty?
      scope = sort_scope(scope, section, **sort_options)
      scope = scope.distinct if associations.any?(&:distinct?)
      scope = scope.none unless section.exists? scope
    else
      flash.now[:alert] = { search: errors }
      scope = scope.none
    end
    all ? scope : page_scope(scope, section, **sort_options)
  end

  def search_section
    search = section(action.name)
    search = section(:index) unless search.is_a? Admin::Sections::Index
    search
  end

  private

  def select_columns(scope, section)
    columns = section.include_columns
    excepts = section.exclude_columns
    columns -= excepts
    if columns.present?
      columns << section.model.primary_key
      return scope.select(*columns.to_a)
    end
    if excepts.present?
      return scope.select_without(*excepts.to_a)
    end
    scope
  end

  # NOTE reserved characters
  # \s: [escapable] AND condition (ex.: "searching words" --> ... ILIKE 'searching' AND ... ILIKE 'words')
  # " : [escapable] preserve query string words grouping (ex.: "in this order" --> ... ILIKE 'in this order')
  # ^ : transform string to "starting with%" for ILIKE (ex.: "^starting with")
  # $ : transform string to "%ending with" for ILIKE (ex.: "ending with$")
  # {}: specify semicolon-separated fields (ex.: {namespaced-model_name.field_name|other_field})
  # _ : used in fields {_} to reuse the previous specified fields (ex.: {name}>2 {_}<5))
  # = : comparison operators == and = or ILIKE for string
  # ! : comparison operators != and ! (! is the same as !=)
  # < : comparison operators < and <=
  # > : comparison operators > and >=
  # | : OR condition for multiple fields (ex.: {field_1|field_2}) or operators (ex.: =value_1|=value_2)
  # , : [escapable] IN operator for multiple tokens (ex.: =value_1,value_2 --> ... IN ('value_1','value_2'))
  def query_scope(scope, section, query)
    query = MixAdmin::Routes.format_query_param(query)
    return [scope, []] unless query.is_a?(String) && query.present?
    query_fields = section.query_fields.with_indifferent_access
    fields_default = query_fields.transform_values{ |v| v.keys.map(&:to_s).to_set }
    statements, errors = parse_query(query)
    statements.each do |statement|
      tables, ors, values = Set.new, [], []
      statement.each do |type, fields_hash, operator, value, statement_was|
        fields_base = fields_hash&.dig(:_base)
        if (fields_hash = fields_hash&.except(:_base).presence)
          fields_hash = fields_default.transform_values{ |v| v & fields_base }.union(fields_hash) if fields_base
        else
          fields_hash = fields_base ? fields_default.transform_values{ |v| v & fields_base } : fields_default
        end
        fields_hash.each do |model_param, fields_set|
          next errors << [:model, statement_was] unless (model_fields = query_fields[model_param])
          fields = fields_set.map{ |field_name| model_fields[field_name] }
          case type
          when :blank
            fields.reject!{ |field| field.nil? || field.required? }
          when :present
            fields.compact!
          else
            fields.select!{ |field| field&.search_type == type }
          end
          fields.each do |field|
            next if (field_value = parse_search_value(field, value)) == :_skip
            table, column = (full_column = field.query_column).split('.')
            tables << table
            column = full_column if field.full_query_column?
            values.concat(Array.wrap(field_value))
            ors << field.search_operator(operator).gsub('{column}', column)
          end
        end
        errors << [:fields, statement_was] if tables.empty?
      end
      scope = ors_scope(scope, tables, ors, values)
    end
    [scope, errors]
  end

  def ors_scope(scope, tables, ors, values)
    ors_statement = ors.size <= 1 ? ors.first : "(#{ors.join(') OR (')})"
    scope = ors_statement ? scope.where(ors_statement, *values) : scope
    scope = scope.references(*tables.to_a) unless tables.empty?
    scope
  end

  def parse_search_value(field, value)
    return field.parse_search(value) unless value.is_a? Array
    value = value.each_with_object([]) do |v, array|
      next if (v = field.parse_search(v)) == :_skip
      array << v
    end
    value.empty? ? :_skip : value
  end

  def sort_scope(scope, section, name:, reverse:)
    return scope if section.countless?
    scope = scope.reorder(name.sql_safe)
    scope = scope.reverse_order if reverse.to_b
    scope
  end

  def page_scope(scope, section, name:, reverse:)
    return scope unless section.paginate?
    per_page = section.items_per_page
    return set_page_and_extract_portion_from(scope, per_page: per_page) unless section.countless?
    attribute = name.to_s.split('.').last
    set_page_and_extract_portion_from(scope, per_page: per_page, ordered_by: { attribute => (reverse ? :desc : :asc) })
  end

  def parse_query(query)
    fields = nil
    query = escape_string(query).gsub(/(\S)"/, '\1 "').gsub(/"(\S)/, '" \1').squish
    query.split(STATEMENTS).each_with_object([[], []]) do |statement, (ands_of_ors, errors)|
      ors = []
      statement_was = unescape_string(statement)
      statement, fields = split_statement_fields(statement, fields)
      case statement
      when nil
        next errors << [:statement, statement_was]
      when /^#{OPERATOR}[^=" ]/
        statement.split(/#{OR}?(#{OPERATOR})/).drop(1).each_with_index do |operator_or_token, i|
          next ors << parse_operator(operator_or_token) if i.even?
          type, value = parse_token(operator_or_token)
          next (errors << [:value, statement_was]) && ors.pop if type.nil?
          operator, type, value = build_token_statement(ors.last, type, value)
          next (errors << [:operator, statement_was]) && ors.pop if operator.nil?
          ors[-1] = [type, fields, operator, value, statement_was]
        end
      else
        case statement
        when QUOTED_STRING
          statement.gsub! QUOTES, ''
          next errors << [:empty, statement_was] if statement.blank?
        when /^#{OPERATOR}$/
          next errors << [:empty, statement_was]
        end
        operator, type, value = build_string_statement(statement)
        ors << [type, fields, operator, value, statement_was]
      end
      ands_of_ors << ors.select do |result|
        next true if result.size == 5
        errors << [:empty, statement_was] # operator without value
        false
      end
    end
  end

  def split_statement_fields(statement, fields_was)
    model_statements, fields, fields_statements = statement.partition(/^\{#{FIELD}(#{OR}#{FIELD})*\}/)
    statement = case
      when fields.blank?
        model_statements.presence
      when fields == IDEM
        fields = fields_was
        fields_statements
      when fields_statements.present?
        fields.gsub! BRACES, ''
        fields = fields.split(OR).each_with_object({}) do |field, hash|
          model_param, field_name = field.split('.')
          if field_name.nil?
            field_name = model_param
            model_param = :_base
          end
          (hash[model_param] ||= Set.new) << field_name
        end
        fields_statements
      end
    [statement, fields.presence]
  end

  def build_string_statement(statement)
    value = parse_string(statement)
    ['{column} ILIKE ?', :string, value]
  end

  def build_token_statement(operator, type, value)
    if value.is_a? Array
      return case operator
        when EQUAL     then ["{column} IN (#{value.map{ '?' }.join(',')})", type, value]
        when NOT_EQUAL then ["{column} NOT IN (#{value.map{ '?' }.join(',')})", type, value]
        end
    end
    operator = case type
      when :blank
        ### NOTE
        # ActiveRecord::Base::WithNullifyBlanks used
        return case operator
          when EQUAL     then ['{column} IS NULL', type, value]
          when NOT_EQUAL then ['{column} IS NOT NULL', :present, value]
          end
      when :boolean
        case operator
        when EQUAL     then value ? operator : 'IS NULL OR {column} ='
        when NOT_EQUAL then value ? 'IS NULL OR {column} !=' : operator
        else return
        end
      when :datetime
        if value.is_a? Range
          value = [value.begin, value.end]
          case operator
          when EQUAL     then 'BETWEEN ? AND'
          when NOT_EQUAL then 'NOT BETWEEN ? AND'
          else return
          end
        else
          operator
        end
      when :uuid
        return unless operator.in? [EQUAL, NOT_EQUAL]
        operator
      when :string
        case operator
        when EQUAL     then 'ILIKE'
        when NOT_EQUAL then 'NOT ILIKE'
        else operator
        end
      else
        operator
      end
    ["{column} #{operator} ?", type, value]
  end

  def parse_token(token, array = false)
    return if token.blank?
    case token
    when '_null'       then [:blank, nil]
    when BOOLEAN       then [:boolean, token.delete_prefix('_').to_b]
    when DATETIME      then [:datetime, ::Time.parse_utc(token)]
    when '_today'      then [:datetime, date_range(:today)]
    when '_past_hour'  then [:datetime, date_range(:hour)]
    when '_past_day'   then [:datetime, date_range(:day)]
    when '_past_week'  then [:datetime, date_range(:week)]
    when '_past_month' then [:datetime, date_range(:month)]
    when '_past_year'  then [:datetime, date_range(:year)]
    when String::UUID  then [:uuid, token]
    when IN
      token.split(',').each_with_object([nil, []]) do |token, type_values|
        type_was, values = type_values
        type, value = parse_token(token, true)
        return if type.nil? || type == :blank || (type_was && type_was != type)
        type_values[0] = type if type_was.nil?
        values << value
      end
    else
      case
      when token.to_i? then [:numeric, token.to_i]
      when token.to_f? then [:numeric, token.to_f]
      when token.to_d? then [:numeric, token.to_d]
      when array
        [:string, simplify_search_string ? token.simplify : token]
      else
        [:string, parse_string(token)]
      end
    end
  end

  def parse_string(string)
    string = unescape_string(string)
    string.gsub! SINGLE_QUOTES, '' if string.match? SINGLE_QUOTED_STRING
    start_with = !!string.delete_prefix!('^')
    end_with = !!string.delete_suffix!('$')
    string = simplify_search_string ? string.simplify : ActiveRecord::Base.sanitize_sql_like(string)
    return string if start_with && end_with
    return string.concat('%') if start_with
    return string.prepend('%') if end_with
    "%#{string}%"
  end

  def parse_operator(operator)
    case operator
    when '==' then EQUAL
    when '!'  then NOT_EQUAL
    else operator
    end
  end

  def date_range(type)
    if type == :today
      Time.current.beginning_of_day..Time.current.end_of_day
    else
      1.public_send(type).ago.public_send("beginning_of_#{type}")..Time.current.end_of_hour
    end
  end

  def escape_string(string)
    string.gsub(/\\ /, SPACE).gsub(/\\,/, COMMA).gsub(/\\"/, QUOTE)
  end

  def unescape_string(string)
    string.gsub(SPACE, ' ').gsub(COMMA, ',').gsub(QUOTE, '"')
  end
end
