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
    result = callback.apply(this, arguments)
    delete this.self
    delete this.super
    result

window.polyfill = (object, name, callback) ->
  object[name] ?= ->
    callback.apply(this, arguments)

window.warn_defined_key = (klass, name) =>
  if klass::[name]
    klass_name = klass.class_name or klass.name
    Logger.debug "ExtCoffee Overriding #{klass_name}.prototype.#{name}"

window.warn_defined_singleton_key = (klass, name) =>
  if klass[name]
    klass_name = klass.class_name or klass.name or klass.constructor.name
    Logger.debug "ExtCoffee Overriding #{klass_name}.#{name}"

window.primitive = (object) ->
  not object? or (typeof object isnt 'object' and typeof object isnt 'function')

window.type_caster = (object) ->
  cast = 'to_null' unless object?
  cast ? switch object.constructor
    when Number
      if object.is_integer() then 'to_i' else 'to_f'
    when Boolean             then 'to_b'
    when Date                then 'to_date'
    when Duration            then 'to_duration'
    when Array               then 'to_a'
    when Object              then 'to_h'

for type in [Array, Boolean, Date, Element, Function, Math, Number, Object, RegExp, String]
  do (type) ->
    type.override_singleton_methods = (methods) ->
      for name, callback of methods
        type.override_singleton_method(name, callback)

    type.override_singleton_method = (name, callback) ->
      type.define_singleton_method(name, callback, false)

    type.define_singleton_methods = (methods) ->
      for name, callback of methods
        type.define_singleton_method(name, callback)

    type.define_singleton_method = (name, callback, warn = true) ->
      warn_defined_singleton_key(type, name) if warn
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
      warn_defined_key(type, name) if warn
      type::[name] = callback
      Object.defineProperty(type::, name, enumerable: false)

    type.define_readers = (methods) ->
      for name, callback of methods
        type.define_reader(name, callback)

    type.define_reader = (name, callback) ->
      warn_defined_key(type, name)
      Object.defineProperty(type::, name, enumerable: false, get: callback)

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
  warn_defined_singleton_key(JSON, name)
  JSON[name] = callback

class window.WithReaders
  @readers: (methods) ->
    for name, callback of methods
      @reader(name, callback)

  @reader: (name, callback) ->
    Object.defineProperty(@::, name, enumerable: false, get: callback)
