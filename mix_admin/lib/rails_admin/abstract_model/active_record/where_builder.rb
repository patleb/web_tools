module RailsAdmin
  class AbstractModel::ActiveRecord::WhereBuilder
    def initialize(scope)
      @statements = []
      @values = []
      @tables = []
      @scope = scope
    end

    def add(field, value, operator)
      field.searchable_columns.flatten.each do |column_infos|
        # TODO if from same column, then OR statements instead of 'where'
        builder = AbstractModel::ActiveRecord::StatementBuilder.new(column_infos[:column], column_infos[:type], value, operator)
        statement, value1, value2 = builder.to_statement
        @statements << statement if statement.present?
        @values << value1 unless value1.nil?
        @values << value2 unless value2.nil?
        table, column = column_infos[:column].split('.')
        @tables.push(table) if column
      end
    end

    def build
      statement = @statements.size <= 1 ? @statements.first : "(#{@statements.join(') OR (')})"
      scope = statement ? @scope.where(statement, *@values) : @scope
      scope = scope.references(*@tables.uniq) if @tables.any?
      scope
    end
  end
end
