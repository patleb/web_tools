Array.wrap = (object) ->
  if object?
    if Array.is_array(object)
      Array::slice.call(object)
    else
      [object]
  else
    []
