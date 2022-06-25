Number.override_methods
  blank: ->
    isNaN(this)

  eql: (other) ->
    this is other

Number.define_methods
  to_b: ->
    return true if this is 1
    return false if this is 0
    throw 'invalid value for Boolean'

  to_i: ->
    parseInt(this)

  to_f: ->
    @valueOf()

  to_d: ->
    @valueOf()

  to_s: ->
    @toString()

  is_integer: ->
    @constructor.isInteger?(this) ? @is_finite() and @floor() is this

  is_finite: ->
    @constructor.isFinite?(this) ? this isnt Infinity and this isnt -Infinity

  safe_text: ->
    @toString()

  even: ->
    this % 2 is 0

  odd: ->
    Math.abs(this % 2) is 1

  ceil: ->
    Math.ceil(this)

  floor: ->
    Math.floor(this)

  round: ->
    Math.round(this)

  html_safe: ->
    true
