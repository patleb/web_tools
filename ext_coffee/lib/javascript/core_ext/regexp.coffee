RegExp.override_methods
  blank_: ->
    false

  eql_: (other) ->
    return false unless other?.is_a RegExp
    return false unless @source is other.source
    @flags.chars().sort().eql_(other.flags.chars().sort())

RegExp.define_methods
  match: (str) ->
    str.match(this)
