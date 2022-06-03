Function.defer = (fn) ->
  setTimeout(fn, 1)

Function::defer = ->
  @constructor.defer(this)

Object.defineProperty(Function::, 'defer', enumerable: false)
