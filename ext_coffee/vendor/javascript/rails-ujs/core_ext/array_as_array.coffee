Array.as_array = (object) ->
  return false unless object?
  if typeof window.Symbol is 'function'
    typeof object[Symbol.iterator] is 'function' and
    typeof object.length is 'number' and
    typeof object isnt 'string'
  else
    if Array.isArray(object) or
      object instanceof HTMLCollection or
      object instanceof NodeList or
      object instanceof DOMTokenList or
      object instanceof DOMStringList or
      Object.prototype.toString.call(object) is '[object Arguments]'
      return true
    return false if typeof object isnt 'object' or not object.hasOwnProperty('length') or object.length < 0
    return true if object.length is 0
    return true if object[0] and object[0].nodeType
    false
