Array.is_array = (object) ->
  if not object?
    false
  else if typeof window.Symbol is 'function'
    typeof object[Symbol.iterator] is 'function' and
    typeof object.length is 'number' and
    typeof object isnt 'string'
  else if Array.isArray(object) \
  or object instanceof HTMLCollection \
  or object instanceof NodeList \
  or object instanceof DOMTokenList \
  or Object.prototype.toString.call(object) is '[object Arguments]'
    true
  else if typeof object isnt 'object' or not object.hasOwnProperty('length') or object.length < 0
    false
  else
    object.length is 0 or !!(object[0]?.nodeType)
