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

  delegate_to: (receiver, base, keys...) ->
    { force, prefix = '' } = keys.extract_options()
    keys = base.keys() if keys.empty()
    keys.except(Function.PROTECTED_METHODS...).each (key) ->
      if force or not key.start_with('_') # skip private
        if base[key]?.is_a Function
          delegated_key = if prefix.present() then "#{prefix}_#{key}" else key
          previous = receiver[key]
          receiver[delegated_key] = base[key]
          receiver[delegated_key].super = previous if previous?
    receiver

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
  blank: ->
    false

  eql: (other) ->
    this is other

Function.define_methods
  nullary: ->
    @length is 0 and !!@toString().match /^function \w+\(\)/

  throttle: (wait = 0, options = {}) ->
    @constructor.throttle(this, wait, options)

  defer: ->
    @constructor.defer(this)

  delegate_to: (base, keys...) ->
    switch base.constructor
      when String
        if base.start_with '@', 'this.'
          throw 'must specify #delegate_to keys' if keys.empty()
          ivar_name = base.sub(/^(@|this\.)/, '')
          keys.each (method) =>
            this::[method] = ->
              ivar = this[ivar_name]
              ivar[method].apply(ivar, arguments)
        else
          throw 'invalid #delegate_to base'
      when Function
        @constructor.delegate_to(this::, base::, keys...)
      else
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
