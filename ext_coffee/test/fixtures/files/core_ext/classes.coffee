class window.Module
  @extended: (klass) ->
    klass.module = this

  @context: ->
    'Module'

class window.Concern
  @class_methods: (klass) ->
    context: ->
      'Extended'

  @included: (prototype) ->
    prototype.concern = this

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
