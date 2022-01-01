module Enumerable
  alias_method :select_map, :filter_map

  def stable_sort_by!
    sort_by!.with_index{ |obj, i| [yield(obj), i] }
  end

  def stable_sort_by
    sort_by.with_index{ |obj, i| [yield(obj), i] }
  end

  def count_by(sort = nil, &block)
    result = group_by(&block).transform_values!(&:count)
    case sort
    when :desc then result.sort_by(&:last).reverse.to_h
    when :asc  then result.sort_by(&:last).to_h
    else result
    end
  end

  def tally_by(&block)
    map(&block).tally
  end
end
