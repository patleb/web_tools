module Enumerable
  def stable_sort_by
    sort_by.with_index{ |obj, i| [yield(obj), i] }
  end
end
