window.Test = {}
window.Scoped = {}

class Test.SimpleConcept extends Js.Base
  constants: ->
    BODY: '#js_simple_body'
    ROWS: '.js_simple_rows'
    TRIGGERED: 'js_simple_triggered'
    CUSTOM: '.js_simple_custom > a'
    BODY_ROWS: -> "#{@BODY} #{@ROWS}"

  readers: ->
    rows: ->
      dom.$(@ROWS)

  events: -> [
    'click', @BODY, (event, this_was) =>
      event.preventDefault() if event.skip
      event.target.add_class(@TRIGGERED)
      @method = -> 'method'
      @CONSTANT = 'constant'
      @public = 'public'
      @_private = 'private'
      @__system = 'system'
      @rows

    'click', @ROWS, (event, this_was) ->
      event.target.add_class(@TRIGGERED)

    'hover', @ROWS, (event, this_was) ->
      event.preventDefault() if event.skip
      event.target.add_class(@TRIGGERED)
  ]

  events_before: (event) ->
    event.preventDefault() if event.skip_before
    event.events_before = true

  events_after: (event) ->
    event.events_after = true
    @public = 'after'

  ready_once: ->
    @did_ready_once ?= 0
    @did_ready_once++

  ready: ->
    @did_ready ?= 0
    @did_ready++

  leave: ->
    @__did_leave ?= 0
    @__did_leave++

class Js.Component.SimpleElement extends Js.Component.Element
  @readers
    name: -> dom.find(@NAME)
    value: -> 'value'

  constants: ->
    NAME: '.js_simple_name'

  events: -> [
    'hover', @NAME, (event, this_was) ->
      @name.add_class(Test.SimpleConcept.TRIGGERED)
  ]

class Js.Component.ExtendElement extends Js.Component.SimpleElement

# it should not redefine #constants, #readers, #ready(_once), #leave and #events on extends
class Test.ExtendConcept extends Test.SimpleConcept
  events: -> [
    'click', @BODY, @handler
  ]

  handler: (event, this_was) ->
    @inherited = 'inherited'

class Test.GlobalConcept
  global: true

class Test.CustomGlobalConcept
  alias: 'SomeGlobal'

class Test.ScopedGlobalConcept
  alias: 'Scoped.Global'

class Test.NotAConceptName
