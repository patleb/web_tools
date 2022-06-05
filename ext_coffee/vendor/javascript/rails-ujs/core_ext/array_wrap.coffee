Array.wrap = (object) ->
  Array::slice.call(object) if object?
