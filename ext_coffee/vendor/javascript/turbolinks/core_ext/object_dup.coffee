Object::dup = ->
  result = {}
  for key, value of this
    result[key] = value
  result

Object.defineProperty(Object::, 'dup', enumerable: false)
