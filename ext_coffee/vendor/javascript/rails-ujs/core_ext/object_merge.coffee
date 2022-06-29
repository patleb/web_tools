Object.merge = (target, objects...) ->
  for object in objects
    for key, value of object
      target[key] = value
  target

Object::merge = (objects...) ->
  @constructor.merge(this, objects...)

Object.defineProperty(Object::, 'merge', enumerable: false)
