# frozen_string_literal: false

module Numo
  NArray.class_eval do
    # Numo::NArray#to_a.to_s.tr(' ', '').tr('[', '{').tr(']', '}')
    def _to_sql_
      this = flatten.to_a
      return '{}' if (ndims = shape.size) == 0
      return '{' * ndims + '}' * ndims if size == 0
      i = 0
      dim_i = 0
      dim_n = ndims - 1
      counts = shape.dup
      sql = ''
      loop do
        loop do
          sql << '{'
          break if dim_i == dim_n
          dim_i += 1
        end
        loop do
          sql << this[i].to_s
          i += 1
          break if (counts[dim_i] -= 1) == 0
          sql << ','
        end
        loop do
          sql << '}'
          return sql if dim_i == 0
          unless (counts[dim_i - 1] -= 1) == 0
            (dim_i..dim_n).each{ |d| counts[d] = shape[d] }
            sql << ','
            break
          end
          dim_i -= 1
        end
      end
    end
  end
end
