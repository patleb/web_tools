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
  @delegate_to '@constructor', 'constructor_delegate'

  @constructor_delegate: ->
    'Constructor Delegate'

  constructor: (@ivar = 'IVar Delegate') ->

  context: ->
    'Base'

  method: ->
    'Method'

class window.ModuleDelegate
  module_delegate: ->
    'Module Delegate'

class window.Class extends Base
  @extend Module
  @include Concern
  @delegate_to 'this.ivar', 'to_s'
  @delegate_to ModuleDelegate, 'module_delegate'
  @alias_method 'alias', 'method'
