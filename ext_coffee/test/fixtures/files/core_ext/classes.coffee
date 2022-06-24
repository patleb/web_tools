class window.Module
  @extended: ->
    @extended = true

  @context: ->
    'Module'

class window.Concern
  @class_methods: ->
    context: ->
      'Extended'

  @included: ->
    @included = true

  context: ->
    'Concern'

class window.Base
  context: ->
    'Base'

  method: ->
    'Method'

class window.Class extends Base
  @extend Module
  @include Concern

  @alias_method 'alias', 'method'
