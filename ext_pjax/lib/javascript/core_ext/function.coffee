Function.PROTECTED_METHODS = [
  'included'
  'extended'
]

Function.define_singleton_methods
  delegate_to: (receiver, base, keys...) ->
    { force, prefix = '' } = keys.extract_options()
    keys = keys.unsplat()
    keys = base.keys() if keys.empty()
    keys.except(Function.PROTECTED_METHODS).each (key) ->
      if force || !key.start_with('_') # skip private
        if base[key]?.is_a(Function)
          delegated_key = prefix.prefix_of(key)
          previous = receiver[key]
          receiver[delegated_key] = base[key]
          receiver[delegated_key].super = previous if previous?
    receiver

Function.define_methods
  is_a: (klass) ->
    this.constructor == klass

  blank: ->
    false

  present: ->
    true

  presence: ->
    this.valueOf()

  include: (base, keys...) ->
    Function.delegate_to this.prototype, base.prototype, keys...
    base.included?(this.prototype)

  extend: (base, keys...) ->
    Function.delegate_to this, base, keys...
    base.extended?(this)
