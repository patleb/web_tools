module RailsAdmin
  class AbstractModel::ActiveRecord::StatementBuilder
    def initialize(column, type, value, operator)
      @column = column
      @type = type
      @value = value
      @operator = operator
    end

    def to_statement
      return if [@operator, @value].any? { |v| v == '_ignore' }
      unary_operators[@operator] || unary_operators[@value] || build_statement_for_type_generic
    end

    protected

    def build_statement_for_type_generic
      build_statement_for_type || begin
        case @type
        when :date, :datetime, :timestamp
          build_statement_for_datetime
        # TODO
        # when :time
        #   build_statement_for_time
        end
      end
    end

    def build_statement_for_type
      case @type
      when :boolean                                 then build_statement_for_boolean
      when :integer, :decimal, :float, :foreign_key then build_statement_for_number
      when :string, :text, :citext                  then build_statement_for_string
      when :enum, :sti                              then build_statement_for_enum
      when :belongs_to_association                  then build_statement_for_association
      # TODO compare UUIDs --> https://github.com/kelektiv/node-uuid/issues/75
      when :uuid                                    then build_statement_for_uuid
      end
    end

    def build_statement_for_datetime
      start_date, end_date = get_duration
      if @operator == "default"
        start_date = (start_date.beginning_of_day rescue nil) if start_date
        end_date = (end_date.end_of_day rescue nil) if end_date
      end
      range_filter(start_date, end_date)
    end

    def build_statement_for_boolean
      if %w(false f 0).include?(@value)
        ["#{@column} IS NULL OR #{@column} = ?", false]
      elsif %w(true t 1).include?(@value)
        ["#{@column} = ?", true]
      end
    end

    def build_statement_for_number
      case @value
      when Array then
        val, range_begin, range_end = *@value.map do |v|
          next unless v.to_i? || v.to_f?
          @type == :integer || @type == :foreign_key ? v.to_i : v.to_f
        end
        case @operator
        when 'between'
          range_filter(range_begin, range_end)
        else
          column_for_value(val) if val
        end
      else
        if @value.to_i? || @value.to_f?
          @type == :integer || @type == :foreign_key ? column_for_value(@value.to_i) : column_for_value(@value.to_f)
        end
      end
    end

    def build_statement_for_string
      return if @value.blank?
      return ["#{@column} = ?", @value] if ['is', '='].include? @operator

      @value = begin
        case @operator
        when 'default', 'like'
          "%#{@value}%"
        when 'starts_with'
          "#{@value}%"
        when 'ends_with'
          "%#{@value}"
        else
          return
        end
      end

      ["#{@column} ILIKE ?", @value]
    end

    def build_statement_for_enum
      unless @value.blank?
        ["#{@column} IN (?)", Array.wrap(@value)]
      end
    end

    def build_statement_for_association
      unless @value.blank?
        ["#{@column} = ?", @value.to_i] if @value.to_i?
      end
    end

    def build_statement_for_uuid
      if @value.to_s.match? SecureRandom::UUID
        column_for_value(@value)
      end
    end

    ### NOTE
    # ActiveRecord::Base::WithNullifyBlanks used
    def unary_operators
      {
        '_blank' => ["#{@column} IS NULL"],
        '_present' => ["#{@column} IS NOT NULL"],
        '_null' => ["#{@column} IS NULL"],
        '_not_null' => ["#{@column} IS NOT NULL"],
      }
    end

    def range_filter(min, max)
      if min && max
        ["#{@column} BETWEEN ? AND ?", min, max]
      elsif min
        ["#{@column} >= ?", min]
      elsif max
        ["#{@column} <= ?", max]
      end
    end

    def column_for_value(value)
      ["#{@column} = ?", value]
    end

    private

    def get_duration
      case @operator
      when 'between'   then between
      when 'today'     then today
      when 'yesterday' then yesterday
      when 'this_week' then this_week
      when 'last_week' then last_week
      else default_duration
      end
    end

    def today
      today = Time.current
      [today.beginning_of_day, today.end_of_day]
    end

    def yesterday
      yesterday = 1.day.ago
      [yesterday.beginning_of_day, yesterday.end_of_day]
    end

    def this_week
      today = Time.current
      [today.beginning_of_week, today.end_of_week]
    end

    def last_week
      last_week = 1.week.ago
      [last_week.beginning_of_week, last_week.end_of_week]
    end

    def between
      [@value[1], @value[2]]
    end

    def default_duration
      [default_date, default_date]
    end

    def default_date
      Array.wrap(@value).first
    end
  end
end
