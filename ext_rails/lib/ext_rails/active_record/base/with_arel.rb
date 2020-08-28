# TODO
# https://gist.github.com/phlegx/add77d24ebc57f211e8b
# https://gist.github.com/hadees/cff6af2b53d340b9b4b2
# http://radar.oreilly.com/2014/05/more-than-enough-arel.html
module ActiveRecord::Base::WithArel
  extend ActiveSupport::Concern

  included do
    class << self
      alias_method :column, :arel_attribute
    end
  end

  class_methods do
    def alias_table(alias_name, table_name = self.table_name)
      Arel::Table.new(table_name, as: alias_name.to_s)
    end

    def join(table)
      arel_table.join(table.is_a?(ActiveRecord::Base) ? table.arel_table : table)
    end

    def greatest(*args, **options)
      with_columns_and_as(args, options) do |columns, as|
        Arel::Nodes::NamedFunction.new('GREATEST', columns, as)
      end
    end

    def least(*args, **options)
      with_columns_and_as(args, options) do |columns, as|
        Arel::Nodes::NamedFunction.new('LEAST', columns, as)
      end
    end

    private

    def with_columns_and_as(columns, as: nil)
      columns = columns.map do |attr|
        case attr
        when String, Symbol
          (as ||= attr.to_s) && column(attr.to_s)
        else
          attr
        end
      end
      yield(columns, as)
    end
  end
end
