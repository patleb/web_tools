window.noop = ->

window.not_implemented = -> throw new Error('NotImplementedError')

window.prepend_to = (object, name, callback) ->
  previous = object[name] || -> {}
  object[name] = ->
    callback.apply(this, arguments)
    previous.apply(this, arguments)

window.append_to = (object, name, callback) ->
  previous = object[name] || -> {}
  object[name] = ->
    previous.apply(this, arguments)
    callback.apply(this, arguments)

window.decorate = (object, name, callback) ->
  previous = object[name] || -> {}
  object[name] = ->
    this.super = previous
    callback.apply(this, arguments)

window.polyfill = (object, name, callback) ->
  object[name] ?= ->
    callback.apply(this, arguments)

for type in [Array, Boolean, Element, Function, JSON, Number, Object, RegExp, String]
  do (type) ->
    type.define_singleton_methods = (methods) ->
      for name, callback of methods
        type.define_singleton_method(name, callback)

    type.define_singleton_method = (name, callback) ->
      Logger.warn_define_singleton_method(type, name)
      type[name] = callback

    type.define_methods = (methods) ->
      for name, callback of methods
        type.define_method(name, callback)

    type.define_method = (name, callback) ->
      Logger.warn_define_method(type, name)
      type::[name] = callback
      Object.defineProperty(type::, name, enumerable: false)

    for pattern in ['prepend_to', 'append_to', 'decorate', 'polyfill']
      do (pattern) ->
        type["#{pattern}_singleton_methods"] = (methods) ->
          for name, callback of methods
            type["#{pattern}_singleton_method"](name, callback)

        type["#{pattern}_singleton_method"] = (name, callback) ->
          window[pattern] type, name, callback

        type["#{pattern}_methods"] = (methods) ->
          for name, callback of methods
            type["#{pattern}_method"](name, callback)

        type["#{pattern}_method"] = (name, callback) ->
          window[pattern] type::, name, callback

for type in [Array, Boolean, Number, Object, RegExp, String]
  do (type) ->
    type::to_json = -> JSON.parse(JSON.stringify(this))
    Object.defineProperty(type::, 'to_json', enumerable: false)
