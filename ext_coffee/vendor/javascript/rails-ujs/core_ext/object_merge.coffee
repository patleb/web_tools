Object.merge = (objects...) ->
  return unless objects.length > 0
  result = {}
  for object in objects
    for key, value of object
      result[key] = value
  result

Object::merge = (objects...) ->
  @constructor.merge(this, objects...)

Object.defineProperty(Object::, 'merge', enumerable: false)
