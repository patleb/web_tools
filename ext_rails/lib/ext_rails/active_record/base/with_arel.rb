module ActiveRecord::Base::WithArel
  extend ActiveSupport::Concern

  class_methods do
    def column(name)
      arel_table[name]
    end

    def alias_table(alias_name)
      Arel::Table.new(table_name, as: alias_name.to_s)
    end

    def join(table)
      arel_table.join(table.is_a?(ActiveRecord::Base) ? table.arel_table : table)
    end

    def greatest(*columns, **)
      with_columns_as(columns, **) do |columns, as|
        Arel::Nodes::NamedFunction.new('GREATEST', columns, as)
      end
    end

    def least(*columns, **)
      with_columns_as(columns, **) do |columns, as|
        Arel::Nodes::NamedFunction.new('LEAST', columns, as)
      end
    end

    private

    def with_columns_as(columns, as: nil)
      columns = columns.map do |attr|
        case attr
        when String, Symbol
          (as ||= attr.to_s) && column(attr.to_s)
        else
          attr
        end
      end
      yield(columns, as.to_s)
    end
  end
end
