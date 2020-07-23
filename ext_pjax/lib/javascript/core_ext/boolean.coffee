Boolean.define_methods
  is_a: (klass) ->
    this.constructor == klass

  to_b: ->
    this.valueOf()

  to_i: ->
    if this.valueOf() then 1 else 0

  to_f: ->
    if this.valueOf() then 1.0 else 0.0

  to_d: ->
    if this.valueOf() then 1.0 else 0.0

  to_s: ->
    this.toString()

  blank: ->
    !this.valueOf()

  present: ->
    this.valueOf()

  presence: ->
    this.valueOf() if this.valueOf()

  eql: (other) ->
    _.isEqual(this, other)

  safe_text: ->
    this.toString()
