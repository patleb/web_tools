RegExp.override_methods
  blank: ->
    false

  eql: (other) ->
    return false unless other?.is_a RegExp
    return false unless @source is other.source
    @flags.chars().sort().eql(other.flags.chars().sort())

RegExp.define_methods
  match: (str) ->
    str.match(this)
