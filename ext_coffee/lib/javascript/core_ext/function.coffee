### References
# https://github.com/jashkenas/underscore/blob/master/modules/throttle.js
# Returns a function, that, when invoked, will only be triggered at most once
# during a given window of time. Normally, the throttled function will run
# as much as it can, without ever going more than once per `wait` duration;
# but if you'd like to disable the execution on the leading edge, pass
# `{leading: false}`. To disable execution on the trailing edge, ditto.
###
Function.PROTECTED_METHODS = [
  'class_methods'
  'included'
  'extended'
]

Function.override_singleton_methods
  deconstantize: (object) ->
    name = object.__name__
    result = name
    while name
      name = object.__scope__
      object = object.__parent__
      result = "#{name}#{result}" if name and object isnt window
    result

Function.define_singleton_methods
  throttle: (fn, wait = 0, options = {}) ->
    if wait is 0
      request = null
      (args...) ->
        request ?= requestAnimationFrame =>
          request = null
          fn.apply(this, args)
    else
      timeout = null; context = null; args = null; result = null
      previous = 0

      later = ->
        previous = if options.leading is false then 0 else Date.now()
        timeout = null
        result = fn.apply(context, args)
        context = args = null unless timeout
        return

      throttled = ->
        _now = Date.now()
        previous = _now if not previous and options.leading is false
        remaining = wait - (_now - previous)
        context = this
        args = arguments
        if remaining <= 0 or remaining > wait
          if timeout
            clearTimeout(timeout)
            timeout = null
          previous = _now
          result = fn.apply(context, args)
          context = args = null unless timeout
        else if not timeout and options.trailing isnt false
          timeout = setTimeout(later, remaining)
        result

      throttled.cancel = ->
        clearTimeout(timeout)
        previous = 0
        timeout = context = args = null
        return

      throttled

  defer: (fn) ->
    setTimeout(fn, 1)

  delegate: (owner, keys..., options) ->
    @delegate_to(owner, options.to, keys..., options)

  delegate_to: (owner, base, keys...) ->
    { force, bind, reader, prefix = '' } = keys.extract_options()
    if is_dynamic = base.is_a String
      throw 'must specify #delegate_to keys' if keys.empty()
      if base.start_with '@', 'this.', 'this::'
        is_ivar = true
        base = base.sub(/^(@|this\.?)/, '')
        if is_prototype = base.starts_with '::'
          base = base.sub(/^::/, '')
      else if is_prototype = base.ends_with '::'
        base = base.sub(/::$/, '')
    else
      keys = base.keys() if keys.empty()
    names = []
    keys.except(Function.PROTECTED_METHODS...).each (key) ->
      return unless force or not key.start_with('_') # skip private
      name = if prefix.present() then "#{prefix}_#{key}" else key
      if is_dynamic
        if reader
          Object.defineProperty owner, name, enumerable: false, get: ->
            receiver = receiver_for(this, base, is_ivar, is_prototype)
            receiver[key]
        else
          owner[name] = ->
            receiver = receiver_for(this, base, is_ivar, is_prototype)
            if bind then receiver[key].apply(receiver, arguments) else receiver[key](arguments...)
        names.push name
      else if (reader = Object.getOwnPropertyDescriptor(base, key).get?) or base[key]?.is_a Function
        if reader
          Object.defineProperty owner, name, enumerable: false, get: -> base[key]
        else
          owner[name] = if bind then base[key].bind(base) else base[key]
        names.push name
    names

  debounce: (fn, wait = 100, immediate = false) ->
    timeout = null
    (args...) ->
      self = this
      delayed = ->
        fn.apply(self, args) unless immediate
        timeout = null
      if timeout
        clearTimeout(timeout)
      else if (immediate)
        fn.apply(self, args)
      timeout = setTimeout delayed, wait

Function.override_methods
  deconstantize: ->
    @constructor.deconstantize(this)

  blank: ->
    false

  eql: (other) ->
    this is other

Function.define_methods
  throttle: (wait = 0, options = {}) ->
    @constructor.throttle(this, wait, options)

  defer: ->
    @constructor.defer(this)

  delegate: (keys..., options) ->
    @delegate_to(options.to, keys..., options)

  delegate_to: (base, keys...) ->
    base = (base::) if base.constructor is Function
    @constructor.delegate_to(this::, base, keys...)

  new: (args...) ->
    new this(args...)

  include: (base, keys...) ->
    @extend base.class_methods() if base.class_methods?
    @delegate_to base, keys...
    base.included?.apply(this::)
    return

  extend: (base, keys...) ->
    @constructor.delegate_to this, base, keys...
    base.extended?.apply(this)
    return

  alias_method: (to, from) ->
    this::[to] = this::[from]
    return

  debounce: (wait = 100, immediate = false) ->
    @constructor.debounce(this, wait, immediate)

  nullary: ->
    @length is 0 and !!@toString().match /^function \w+\(\)/

receiver_for = (owner, base, is_ivar, is_prototype) ->
  if is_ivar
    receiver = owner
    receiver = (receiver::) if is_prototype
    receiver[base]
  else
    receiver = base.constantize()
    receiver = (receiver::) if is_prototype
    receiver
