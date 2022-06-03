Function.throttle = (fn) ->
  request = null
  (args...) ->
    request ?= requestAnimationFrame =>
      request = null
      fn.apply(this, args)

Function::throttle = ->
  @constructor.throttle(this)

Object.defineProperty(Function::, 'throttle', enumerable: false)
