window.noop = ->

window.not_implemented = -> throw new Error('NotImplementedError')

window.prepend_to = (object, name, callback) ->
  previous = object[name]
  object[name] = ->
    callback.apply(this, arguments)
    previous.apply(this, arguments)

window.append_to = (object, name, callback) ->
  previous = object[name]
  object[name] = ->
    previous.apply(this, arguments)
    callback.apply(this, arguments)

window.decorate = (object, name, callback) ->
  previous = object[name]
  object[name] = ->
    this.self = object
    this.super = previous
    callback.apply(this, arguments)

window.polyfill = (object, name, callback) ->
  object[name] ?= ->
    callback.apply(this, arguments)

window.warn_define_method = (klass, name) =>
  if klass::[name]
    klass_name = klass.class_name or klass.name
    Logger.debug "ExtCoffee Overriding #{klass_name}.prototype.#{name}"

window.warn_define_singleton_method = (klass, name) =>
  if klass[name]
    klass_name = klass.class_name or klass.name or klass.constructor.name
    Logger.debug "ExtCoffee Overriding #{klass_name}.#{name}"

for type in [Array, Boolean, Date, Element, Function, Math, Number, Object, RegExp, String]
  do (type) ->
    type.define_singleton_methods = (methods) ->
      for name, callback of methods
        type.define_singleton_method(name, callback)

    type.define_singleton_method = (name, callback) ->
      warn_define_singleton_method(type, name)
      type[name] = callback

    type.override_methods = (methods) ->
      for name, callback of methods
        type.override_method(name, callback)

    type.override_method = (name, callback) ->
      type.define_method(name, callback, false)

    type.define_methods = (methods) ->
      for name, callback of methods
        type.define_method(name, callback)

    type.define_method = (name, callback, warn = true) ->
      warn_define_method(type, name) if warn
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

JSON.define_singleton_methods = (methods) ->
  for name, callback of methods
    JSON.define_singleton_method(name, callback)

JSON.define_singleton_method = (name, callback) ->
  warn_define_singleton_method(JSON, name)
  JSON[name] = callback
