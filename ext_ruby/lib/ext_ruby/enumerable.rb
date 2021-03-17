module Enumerable
  alias_method :select_map, :filter_map

  def stable_sort_by
    sort_by.with_index{ |obj, i| [yield(obj), i] }
  end
end
