RegExp.define_methods
  is_a: (klass) ->
    this.constructor == klass

  blank: ->
    false

  present: ->
    true

  presence: ->
    this.valueOf()

  eql: (other) ->
    _.isEqual(this, other)

  match: (str) ->
    str.match(this)
