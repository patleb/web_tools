window.noop = ->

window.not_implemented = -> throw new Error('NotImplementedError')

window.eql = (value, other) ->
  value is other or !!value?.eql(other)

window.prepend_to = (object, name, callback) ->
  previous = object[name]
  object[name] = ->
    callback.apply(this, arguments)
    previous.apply(this, arguments)

window.append_to = (object, name, callback) ->
  previous = object[name]
  object[name] = ->
    result = previous.apply(this, arguments)
    callback.apply(this, [arguments..., result])

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
  cast ? object.constructor.from_string?() # returned method name must be defined on String

window.json_caster = (object) ->
  return unless object?
  cast = object.constructor.from_json?()
  cast ?= ('nan' if object.is_nan?())
  cast ? switch object
    when  Infinity then  'inf'
    when -Infinity then '-inf'

window.css = (name, fallback = null) ->
  @_css ?= if window.CSS?.supports('color', 'var(--test)')
    style = getComputedStyle(document.documentElement)
    Array.from(style).select_map (key) ->
      return unless key.starts_with '--'
      return unless value = style.getPropertyValue(key).strip()
      [key, value]
    .to_h()
  else
    {}
  @_css[name] ? fallback

if module.hot and Env.development
  emitter = require('webpack/hot/emitter')

  reset_css = (hash) ->
    window._css = null
    document.dispatchEvent(new CustomEvent('webpack:hot-update', { detail: { hash } }))

  document.addEventListener 'DOMContentLoaded', ->
    emitter.on 'webpackHotUpdate', reset_css

  window.addEventListener 'beforeunload', ->
    emitter.off 'webpackHotUpdate', reset_css

for type in [Array, Boolean, Date, Element, Function, Number, Object, RegExp, String]
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

    type.define_writers = (methods) ->
      for name, callback of methods
        type.define_writer(name, callback)

    type.define_writer = (name, callback) ->
      warn_defined_key(type, name)
      Object.defineProperty(type::, name, enumerable: false, set: callback)

    type.define_accessors = (methods) ->
      for name, callbacks of methods
        type.define_accessor(name, callbacks)

    type.define_accessor = (name, callbacks) ->
      warn_defined_key(type, name)
      { get, set } = callbacks
      Object.defineProperty(type::, name, { enumerable: false, get, set })

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

for type in [JSON, Math]
  do (type) ->
    type.define_singleton_methods = (methods) ->
      for name, callback of methods
        type.define_singleton_method(name, callback)

    type.define_singleton_method = (name, callback, warn = true) ->
      warn_defined_singleton_key(type, name) if warn
      type[name] = callback

class window.WithReaders
  @readers: (methods) ->
    for name, callback of methods
      @reader(name, callback)

  @reader: (name, callback) ->
    Object.defineProperty(@::, name, enumerable: false, get: callback)
