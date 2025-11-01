Number.define_singleton_methods
  with_decimals: (method, value, precision) ->
    string = value.toString()
    if (string.split('.')[1]?.length ? parseInt(string.split('e')[1] or 0)) is precision
      return value.valueOf()
    modifier = 10 ** precision
    Math[method](value * modifier * (1 + Number.EPSILON)) / modifier

Number.override_methods
  blank: ->
    isNaN(this)

  eql: (other) ->
    @valueOf() is other

Number.define_methods
  to_b: ->
    return true if @valueOf() is 1
    return false if @valueOf() is 0
    throw 'invalid value for Boolean'

  to_i: ->
    parseInt(this)

  to_f: ->
    @valueOf()

  to_d: ->
    @valueOf()

  to_s: ->
    @toString()

  to_date: ->
    new Date(this)

  is_integer: ->
    @constructor.isInteger?(@valueOf()) ? @is_finite() and @floor() is @valueOf()

  is_finite: ->
    @constructor.isFinite?(@valueOf()) ? @valueOf() isnt Infinity and @valueOf() isnt -Infinity

  safe_text: ->
    @toString()

  even: ->
    this % 2 is 0

  odd: ->
    Math.abs(this % 2) is 1

  ceil: (precision = 0) ->
    Number.with_decimals 'ceil', this, precision

  floor: (precision = 0) ->
    Number.with_decimals 'floor', this, precision

  round: (precision = 0) ->
    Number.with_decimals 'round', this, precision

  trunc: (precision = 0) ->
    Number.with_decimals 'trunc', this, precision

  html_safe: ->
    true
