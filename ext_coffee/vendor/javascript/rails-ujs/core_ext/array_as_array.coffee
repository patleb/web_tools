Array.as_array = (object) ->
  return true if Array.isArray(object)
  return true if object instanceof HTMLCollection or object instanceof NodeList or object instanceof DOMTokenList
  return true if Object.prototype.toString.call(object) is '[object Arguments]'
  return false if typeof object isnt 'object' or not object.hasOwnProperty('length') or object.length < 0
  return true if object.length is 0
  return true if object[0] and object[0].nodeType
  false
