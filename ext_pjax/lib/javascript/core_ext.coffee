Js.prepend_to = (object, name, callback) ->
  previous = object[name] || -> {}
  object[name] = ->
    callback.apply(this, arguments)
    previous.apply(this, arguments)

Js.append_to = (object, name, callback) ->
  previous = object[name] || -> {}
  object[name] = ->
    previous.apply(this, arguments)
    callback.apply(this, arguments)

Js.decorate = (object, name, callback) ->
  previous = object[name] || -> {}
  object[name] = ->
    this.super = previous
    callback.apply(this, arguments)

for type in [Array, Boolean, Function, jQuery, JSON, Number, Object, RegExp, String]
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

    for pattern in ['prepend_to', 'append_to', 'decorate']
      do (pattern) ->
        type["#{pattern}_singleton_methods"] = (methods) ->
          for name, callback of methods
            type["#{pattern}_singleton_method"](name, callback)

        type["#{pattern}_singleton_method"] = (name, callback) ->
          Js[pattern] type, name, callback

        type["#{pattern}_methods"] = (methods) ->
          for name, callback of methods
            type["#{pattern}_method"](name, callback)

        type["#{pattern}_method"] = (name, callback) ->
          Js[pattern] type::, name, callback
