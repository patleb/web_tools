Function.PROTECTED_METHODS = [
  'included'
  'extended'
]

Function.define_singleton_methods
  delegate_to: (receiver, base, keys...) ->
    { force, prefix = '' } = keys.extract_options()
    keys = base.keys() if keys.empty()
    keys.except(Function.PROTECTED_METHODS...).each (key) ->
      if force || !key.start_with('_') # skip private
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

Function.define_methods
  is_a: (klass) ->
    @constructor is klass

  blank: ->
    false

  present: ->
    true

  presence: ->
    @valueOf()

  eql: (other) ->
    this is other

  include: (base, keys...) ->
    Function.delegate_to this::, base::, keys...
    base.included?(this::)

  extend: (base, keys...) ->
    Function.delegate_to this, base, keys...
    base.extended?(this)

  debounce: (wait = 100, immediate = false) ->
    @constructor.debounce(this, wait, immediate)
