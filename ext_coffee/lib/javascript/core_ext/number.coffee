Number.define_methods
  is_a: (klass) ->
    @constructor is klass

  to_b: ->
    return true if this is 1
    return false if this is 0
    throw "invalid value for Boolean: '#{this}'"

  to_i: ->
    parseInt(this)

  to_f: ->
    @valueOf()

  to_d: ->
    @valueOf()

  to_s: ->
    @toString()

  blank: ->
    isNaN(this)

  present: ->
    not @blank()

  presence: ->
    @valueOf() unless @blank()

  eql: (other) ->
    this is other

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
