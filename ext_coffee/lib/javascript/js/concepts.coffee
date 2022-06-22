class Js.Concepts
  MODULE = /^(?![A-Z]\w*Concept$)[A-Z]/
  CONCEPT = /Concept$/
  ELEMENT = /Element$/
  CONSTANT = /^[A-Z][A-Z0-9_]*/
  CLASS_TYPE = /(Concept|Element)$/

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
    document.addEventListener 'DOMContentLoaded', @on_load
    document.addEventListener 'turbolinks:before-render', @on_leave
    document.addEventListener 'turbolinks:load', @on_ready

  @on_load: =>
    # necessary for having accurate heights/widths
    retries = 0
    test = setInterval =>
      if Env.test or document.styleSheets[0]?.cssRules?.length or retries >= 50
        Logger.debug("CSS load #{retries * 13} ms")
        clearInterval(test)
        while @instances.ready_once.length
          concept = @instances.ready_once.shift()
          concept.ready_once()
          concept.READY_ONCE_IVARS = []
          concept.each (key, value) ->
            unless not_nullifyable(key, value)
              concept.READY_ONCE_IVARS.push(key)
        @instances.ready.each (concept) -> concept.ready()
      else
        retries++
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
    names = name.split('.')
    module ||= (names.length && names[0..-2].join('.')) or ''
    class_name = names.last()

    if uniq_classes[name]
      return Logger.debug("Concept #{name} already defined")
    uniq_classes[name] = true

    concept_class = name.constantize()
    concept_class::module_name = module
    concept_class::class_name = class_name

    module_class = module.constantize()
    module_class[class_name] = concept = new concept_class # singleton

    if concept_class::global is true
      global_name = class_name.sub(CONCEPT, '')
      warn_define_singleton_method(window, global_name)
      window[global_name] = concept

    if (alias = concept_class::alias)
      if alias.include '.'
        [scope..., alias] = alias.split('.')
        scope = scope.join('.').constantize()
      else
        scope = window
      warn_define_singleton_method(scope, alias)
      scope[alias] = concept

    @define_constants(concept_class)
    @define_getters(concept_class)
    @unless_defined concept_class::document_on, =>
      @define_document_on(concept_class, concept)

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

    concept_class::ready_elements ?= (selector) ->
      return unless (elements = Rails.$(selector)).present()

      @elements = elements.each_with_object {}, (element, memo) =>
        element_class = "#{type.camelize()}Element" if type = element.getAttribute('data-element')
        element_class ||= 'Element'
        uid = Math.uid()
        element.setAttribute('data-uid', uid)
        memo[uid] = new this[element_class](element)
        memo[uid].uid = uid

      @elements.each (uid, element) ->
        element.ready?()

    concept_class::leave_elements ?= ->
      @elements?.each (uid, element) ->
        element.leave?()

    concept_class::select((name) -> name.match(ELEMENT)).each (name, element_class) =>
      @add_element(name, element_class, concept) unless element_class.class_name

  # Private

  @nullify_on_leave: ->
    @GETTERS.each (name) => this["__#{name}"] = null
    @each (key, value) =>
      unless not_nullifyable(key, value) or @READY_ONCE_IVARS?.include(key)
        this[key] = null

  @add_element: (name, element_class, concept) ->
    element_class::concept = concept
    element_class.class_name = element_class::class_name = name

    concept.constructor::CONSTANTS.each (name, value) ->
      element_class::[name] = value
    @define_constants(element_class)
    @define_getters(element_class)
    @unless_defined element_class::document_on, =>
      @define_document_on(element_class, element_class::)

  @define_constants: (klass) ->
    constants = @unless_defined klass::constants, =>
      klass::constants().each_with_object {}, (name, value, constants) =>
        @define_constant(klass, name, value, constants)
    klass::CONSTANTS = constants or {}

  @define_constant: (klass, name, value, constants) ->
    if value.class_name
      scope = value.class_name
      scope = value::concept.class_name if scope is 'Element'
      prefix = scope.sub(CLASS_TYPE, '').underscore().upcase()
      shared = name.sub(///#{prefix}_///, '')
      value = if value::?.concept then value::[shared] else value[shared]
    else if value.is_a Function
      return @define_constant(klass, name, value.apply(klass::), constants)
    constants[name] = klass::[name] = value

  @define_getters: (klass) ->
    getters = @unless_defined klass::getters, ->
      klass::getters().each_with_object [], (name, callback, all) ->
        klass::[name] = ->
          this["__#{name}"] ?= callback.apply(this, arguments)
        all.push(name)
    klass::GETTERS = getters or []

  @define_document_on: (klass, context) ->
    klass::document_on().each_slice(3).each ([events, selector, handler]) ->
      with_target = handler
      handler = ->
        args = Array.wrap(arguments)
        args.push(this)
        with_target.apply(context, args)
      if klass::document_on_before
        with_before = handler
        handler = (event) ->
          unless event.defaultPrevented
            klass::document_on_before.apply(context, arguments)
          unless event.defaultPrevented
            with_before.apply(context, arguments)
      if klass::document_on_after
        with_after = handler
        handler = (event) ->
          unless event.defaultPrevented
            with_after.apply(context, arguments)
          unless event.defaultPrevented
            klass::document_on_after.apply(context, arguments)

      events.split(/ *, */).each (event) ->
        Rails.document_on event, selector, handler

  @unless_defined: (method, definition) ->
    if method? and uniq_methods.exclude(method)
      uniq_methods.push(method)
      definition()

  not_nullifyable = (key, value) ->
    not value? or value.is_a(Function) or key.start_with('__') or key.match(CONSTANT)
