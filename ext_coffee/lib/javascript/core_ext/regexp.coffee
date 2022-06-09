RegExp.define_methods
  is_a: (klass) ->
    @constructor is klass

  blank: ->
    false

  present: ->
    true

  presence: ->
    @valueOf()

  eql: (other) ->
    return false unless other?.is_a RegExp
    return false unless @source is other.source
    @flags.chars().sort().eql(other.flags.chars().sort())

  match: (str) ->
    str.match(this)
