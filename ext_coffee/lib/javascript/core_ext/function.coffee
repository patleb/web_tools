Function.PROTECTED_METHODS = [
  'class_methods'
  'included'
  'extended'
]

Function.define_singleton_methods
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
