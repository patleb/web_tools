window.Test = {}
window.Scoped = {}

class Test.SimpleConcept
  constants: =>
    BODY: '#js_simple_body'
    ROWS: '.js_simple_rows'
    TRIGGERED: 'js_simple_triggered'
    CUSTOM: '.js_simple_custom > a'
    BODY_ROWS: => "#{@BODY} #{@ROWS}"

  getters: ->
    rows: ->
      dom.$(@ROWS)

  document_on: => [
    'click', @BODY, (event, target) =>
      event.preventDefault() if event.skip
      target.add_class(@TRIGGERED)
      @method = -> 'method'
      @CONSTANT = 'constant'
      @public = 'public'
      @_private = 'private'
      @__system = 'system'
      @rows()

    'click', @ROWS, (event, target) =>
      target.add_class(@TRIGGERED)

    'hover', @ROWS, (event, target) =>
      event.preventDefault() if event.skip
      target.add_class(@TRIGGERED)
  ]

  document_on_before: (event, target) ->
    event.preventDefault() if event.skip_before
    event.document_on_before = true

  document_on_after: (event, target) ->
    event.document_on_after = true

  ready_once: =>
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

  getters: =>
    body: -> dom.$0(@BODY)

  document_on: => [
    'hover', @BODY, (event, target) =>
      @body().add_class(@TRIGGERED)
  ]

# it should not redefine #constants, #getters, #ready(_once), #leave and #document_on on extends
class Test.ExtendConcept extends Test.SimpleConcept
  document_on: => [
    'click', @BODY, =>
      @inherited = 'inherited'
  ]

class Test.GlobalConcept
  global: true

class Test.CustomGlobalConcept
  global: 'SomeGlobal'

class Test.ScopedGlobalConcept
  global: 'Scoped.Global'

class Test.NotAConceptName
