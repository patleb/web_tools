Object.dup = (object) ->
  result = {}
  for key, value of object
    result[key] = value
  result

Object::dup = ->
  @constructor.dup(this)

Object.defineProperty(Object::, 'dup', enumerable: false)
