class Js.Concepts
  MODULE = /^(?![A-Z]\w*Concept$)[A-Z]/
  CONCEPT = /Concept$/
  ELEMENT = /Element$/
  CONSTANT = /^[A-Z][A-Z0-9_]*/

  uniq_methods = []
  uniq_classes = {}
  initialized = false

  @instances:
    ready_once: []
    ready: []
    leave: []
    leave_clean: []

  @initialize: ({ concepts = [], modules = [], except = [] } = {}) ->
    if initialized
      return Logger.debug('Js.Concepts already initialized')
    initialized = true
    Array.wrap(concepts).each (name) => @add_concept(name)
    Array.wrap(modules).each (name) => @add_module(name)
    Rails.document_on 'DOMContentLoaded', @on_load
    Rails.document_on 'turbolinks:before-render', @on_leave
    Rails.document_on 'turbolinks:load', @on_ready

  @on_load: =>
    # Slight timeout so that the DOM gets properly initialized
    setTimeout =>
      while @instances.ready_once.length
        concept = @instances.ready_once.shift()
        concept.ready_once()
        concept.READY_ONCE_IVARS = []
        concept.each (key, value) ->
          unless not_nullifyable(key, value)
            concept.READY_ONCE_IVARS.push(key)
      @instances.ready.each (concept) ->
        concept.before_ready?()
        concept.ready()
        concept.after_ready?()
    , 13

  @on_leave: (event) =>
    return if event.defaultPrevented
    @instances.leave.each (concept) -> concept.leave()
    @instances.leave_clean.each (concept) -> concept.leave_clean()

  @on_ready: (event) =>
    return if event.data.info.once
    @instances.ready.each (concept) -> concept.ready()

  @add_module: (module) ->
    modules = []
    module.constantize().each (name) =>
      if name.match(MODULE)
        modules.push "#{module}.#{name}"
      else
        @add_concept(name, { module })
    modules.each (module) => @add_module(module)

  @add_concept: (name, { module = null } = {}) ->
    return unless name.match(CONCEPT)
    name = "#{module}.#{name}" if module?
    if uniq_classes[name]
      return Logger.debug("#{name} already initialized")
    uniq_classes[name] = true
    names = name.split('.')
    module ||= (names.length and names[0..-2].join('.')) or 'window'
    class_name = names.last()

    module_class = module.constantize()
    concept_class = name.constantize()
    concept_class::class_name = class_name
    # NOTE: concept becomes a singleton where concept_class is concept.constructor
    module_class[class_name] = concept = new concept_class

    if concept_class::global is true
      global_name = class_name.sub(CONCEPT, '')
      warn_defined_singleton_key(window, global_name)
      window[global_name] = concept
    if (alias = concept_class::alias)
      if alias.include '.'
        [scope..., alias] = alias.split('.')
        scope = scope.join('.').constantize()
      else
        scope = window
      unless scope is Js and alias is 'Component'
        warn_defined_singleton_key(scope, alias)
      scope[alias] = concept

    @define_constants(concept_class)
    @define_memoizers(concept_class)
    @define_store(concept_class)
    @unless_defined concept_class::listeners, =>
      @define_listeners(concept)

    @instances.except('leave_clean').each (phase, all) =>
      @unless_defined concept_class::[phase], ->
        all.push(concept)
    concept.leave_clean = @nullify_on_leave.bind(concept)
    @instances.leave_clean.push(concept)

    concept_class::ready_again ?= ->
      @leave?()
      @leave_clean()
      @ready?()
      true

    concept_class::each(@add_element) if concept is Js.Component

    @define_storage_scopes(concept_class, concept)

  # Private

  @nullify_on_leave: ->
    @nullify_memoizers()
    @each (key, value) =>
      unless not_nullifyable(key, value) or @READY_ONCE_IVARS?.include(key)
        this[key] = null

  @add_element: (name, element_class) =>
    return unless name.match(ELEMENT)
    return if element_class.class_name
    element_class.class_name = element_class::class_name = name
    element_class::element_name = name.sub(ELEMENT, '').underscore('_')

    if (alias = element_class::alias)
      if alias.include '.'
        [scope..., alias] = alias.split('.')
        scope = scope.join('.').constantize()
      else
        scope = window
      warn_defined_singleton_key(scope, alias)
      scope[alias] = element_class::constructor

    @define_constants(element_class)
    @define_memoizers(element_class)
    @unless_defined element_class::listeners, =>
      @define_listeners(element_class::)

  @define_constants: (klass) ->
    constants = @unless_defined klass::constants, =>
      klass::constants().each_with_object {}, (name, value, memo) =>
        @define_constant(klass, name, value, memo)
    klass::CONSTANTS = constants or {}

  @define_constant: (klass, name, value, constants) ->
    if value.is_a Function
      return @define_constant(klass, name, value.apply(klass::), constants)
    constants[name] = klass::[name] = value

  @define_memoizers: (klass) ->
    memoizers = @unless_defined klass::memoizers, ->
      klass::memoizers().each_with_object [], (name, callback, memo) ->
        Object.defineProperty klass::, name, enumerable: false, get: ->
          this["__#{name}"] ?= callback.apply(this, arguments)
        memo.push(name)
    klass::MEMOIZERS = memoizers or []
    klass::nullify_memoizers = ->
      @MEMOIZERS.each (name) => @nullify(name)
    klass::nullify = (name) ->
      this["__#{name}"] = null

  @define_store: (klass) ->
    klass::store = (name, value) ->
      if arguments.length is 1
        (@__store ||= {})[name]
      else
        (@__store ||= {})[name] = value

  @define_storage_scopes: (klass, context) ->
    return unless klass.storage_scopes
    klass::storage_scopes ?= ({ detail: { scope } } = {}) ->
      return unless scope is '' or @constructor.storage_scopes[scope]
      @nullify_memoizers()
    @define_listener(context, Js.Storage.CHANGE, Js.Storage.ROOTS, klass::storage_scopes)

  @define_listeners: (context) ->
    context.listeners().each_slice(3).each ([events, selector, handler]) =>
      @define_listener(context, events, selector, handler)

  @define_listener: (context, events, selector, handler) ->
    with_target = handler
    handler = ->
      with_target.apply(context, [arguments..., this])
    events.split(/ *, */).each (event) ->
      Rails.document_on event, selector, handler

  @unless_defined: (method, definition) ->
    if method? and uniq_methods.exclude(method)
      uniq_methods.push(method)
      definition()

  not_nullifyable = (key, value) ->
    not value? or value.is_a(Function) or key.start_with('__') or key.match(CONSTANT)
