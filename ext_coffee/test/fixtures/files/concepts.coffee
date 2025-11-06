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

  document_on: -> [
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

  document_on_before: (event) ->
    event.preventDefault() if event.skip_before
    event.document_on_before = true

  document_on_after: (event) ->
    event.document_on_after = true
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

class Test.SimpleConcept::Element
  constants: ->
    NAME: 'js_simple_name'

  readers: ->
    body: -> dom.find(@BODY)
    value: -> 'value'

  document_on: -> [
    'hover', @BODY, (event, this_was) ->
      @body.add_class(@TRIGGERED)
  ]

class Test.SimpleConcept::ExtendElement extends Test.SimpleConcept::Element

# it should not redefine #constants, #readers, #ready(_once), #leave and #document_on on extends
class Test.ExtendConcept extends Test.SimpleConcept
  document_on: -> [
    'click', @BODY, @handler
  ]

  handler: (event, this_was) ->
    @inherited = 'inherited'

class Test.GlobalConcept extends Js.Base
  global: true

class Test.CustomGlobalConcept extends Js.Base
  alias: 'SomeGlobal'

class Test.ScopedGlobalConcept extends Js.Base
  alias: 'Scoped.Global'

class Test.NotAConceptName extends Js.Base
