Number.METRIC_PREFIX =   ['f', 'p', 'n', 'µ', 'm', 'null', 'k', 'M', 'G', 'T', 'P']
Number.METRIC_EXPONENT = [-15, -12, -9,  -6,  -3,   null,   3,   6,   9,   12,  15]

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
    return false unless other?.is_a Number
    @valueOf() is other.valueOf()

  html_safe: ->
    true

  safe_text: ->
    @toString().html_safe(true)

Number.define_methods
  to_b: ->
    return true if @valueOf() is 1
    return false if @valueOf() is 0
    throw 'invalid value for Boolean'

  to_i: ->
    parseInt(this)

  to_f: ->
    @valueOf()

  to_s: (type = null, precision = null) ->
    switch type
      when 'percent'
        return "#{this * 100} %"
      when 'metric'
        exponent = Math.log10(this)
        i = Math.floor(Math.floor(exponent) / 3) + 5
        if (exponent = Number.METRIC_EXPONENT[i])?
          value = this / (10 ** exponent)
          value = value.round(precision) if precision?
          return "#{value} #{Number.METRIC_PREFIX[i]}"
      when 'decimal'
        value = if precision? then @round(precision) else @valueOf()
        [left, right] = value.toString().split('.')
        return left if not precision? or precision <= 0
        return "#{left}.#{(right or '').ljust precision, '0'}"
    @toString()

  to_date: ->
    new Date(this * 1000)

  is_integer: ->
    @constructor.isInteger?(@valueOf()) ? @is_finite() and @floor() is @valueOf()

  is_finite: ->
    @constructor.isFinite?(@valueOf()) ? @valueOf() isnt Infinity and @valueOf() isnt -Infinity

  even: ->
    this % 2 is 0

  odd: ->
    Math.abs(this % 2) is 1

  abs: ->
    Math.abs(this)

  sign: ->
    Math.sign(this)

  zero: ->
    @valueOf() is 0

  divmod: (value) ->
    [Math.floor(this / value), this % value]

  ceil:  (precision = 0) -> if precision then Number.with_decimals 'ceil',  this, precision else Math.ceil(this)
  floor: (precision = 0) -> if precision then Number.with_decimals 'floor', this, precision else Math.floor(this)
  trunc: (precision = 0) -> if precision then Number.with_decimals 'trunc', this, precision else Math.trunc(this)
  round: (precision = 0) -> Number.with_decimals 'round', this, precision

  second:  -> @seconds()
  seconds: -> new Duration(sign: @sign(), seconds: this)
  minute:  -> @minutes()
  minutes: -> new Duration(sign: @sign(), minutes: this)
  hour:    -> @hours()
  hours:   -> new Duration(sign: @sign(), hours: this)
  day:     -> @days()
  days:    -> new Duration(sign: @sign(), days: this)
  week:    -> @weeks()
  weeks:   -> new Duration(sign: @sign(), weeks: this)
  month:   -> @months()
  months:  -> new Duration(sign: @sign(), months: this)
  year:    -> @years()
  years:   -> new Duration(sign: @sign(), years: this)

  times: (f_index) ->
    [0...this].map(f_index)
