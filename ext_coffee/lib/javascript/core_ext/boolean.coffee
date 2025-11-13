Boolean.override_methods
  blank: ->
    not @valueOf()

  eql: (other) ->
    return false unless other?.is_a Boolean
    @valueOf() is other.valueOf()

  html_safe: ->
    true

  safe_text: ->
    @toString().html_safe(true)

Boolean.define_methods
  to_b: ->
    @valueOf()

  to_i: ->
    if @valueOf() then 1 else 0

  to_f: ->
    if @valueOf() then 1.0 else 0.0

  to_d: ->
    @to_f()

  to_s: ->
    @toString()
