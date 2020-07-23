@Js ||= {}
@Js.ABORT = 'ABORT'

class Js.Concepts
  MODULE = /^(?![A-Z]\w*Concept$)[A-Z]/
  CONCEPT = /Concept$/
  ELEMENT = /Element$/
  CONSTANT = /^[A-Z][A-Z0-9_]*/
  CLASS_TYPE = /(Concept|Element)$/

  life_cycle = {
    ready_once: []
    ready: []
    leave: []
    leave_clean: []
  }
  uniq_methods = []
  uniq_concepts = {}
  initialized = false

  @initialize: ({ concepts = [], modules = [], except = [] } = {}) =>
    if initialized
      return Logger.debug('Js.Concepts already initialized')
    initialized = true

    concepts.each (concept) => @add_concept(concept)
    modules.each (module) => @add_module(module)

    # necessary for having accurate jQuery heights/widths
    retries = 0
    test = setInterval(->
      if $("head > link[href$='.css']").last().prop('sheet')?.cssRules.length || retries >= 50
        Logger.debug("CSS load #{retries * 20} ms")
        clearInterval(test)
        setTimeout(->
          $(document).ready ->
            while life_cycle.ready_once.length
              concept_instance = life_cycle.ready_once.shift()
              concept_instance.ready_once()
              concept_instance.READY_ONCE = []
              concept_instance.each (key, value) ->
                unless not_nullifyable(key, value)
                  concept_instance.READY_ONCE.push(key)
            life_cycle.ready.each (concept) ->
              concept.ready()
            while life_cycle.leave.length
              $.leave_list.push(life_cycle.leave.shift().leave)
            while life_cycle.leave_clean.length
              $.leave_list.push(life_cycle.leave_clean.shift().leave_clean)
        , 80)
      else
        retries++
    , 20)

  @add_module: (module) =>
    modules = []
    module.constantize().each (name) =>
      if name.match(MODULE)
        modules.push "#{module}.#{name}"
      else
        @add_concept(name, { module })
    modules.each (module) => @add_module(module)

  @add_concept: (concept, { module = null } = {}) =>
    return unless concept.match(CONCEPT)

    concept = "#{module}.#{concept}" if module?
    names = concept.split('.')
    module ||= (names.length && names[0..-2].join('.')) || ''
    class_name = names.last()

    if uniq_concepts[concept]
      return Logger.debug("Concept #{concept} already defined")
    uniq_concepts[concept] = true

    concept_class = concept.constantize()
    concept_class::module_name = module
    concept_class::class_name = class_name

    module_class = module.constantize()
    module_class[class_name] = concept_instance = new concept_class

    if (global = concept_class::global)
      global_name = if (global == true) then class_name.sub(CONCEPT, '') else global
      Logger.warn_define_singleton_method(window, global_name)
      window[global_name] = concept_instance

    @define_constants(concept_class)
    @define_accessors(concept_class)
    @unless_defined concept_class::document_on, =>
      @define_document_on(concept_instance)

    life_cycle.except('leave_clean').each (phase, all) =>
      @unless_defined concept_class::[phase], ->
        all.push(concept_instance)

    concept_instance.leave_clean = @nullify_on_leave.bind(concept_instance)
    life_cycle.leave_clean.push(concept_instance)

    concept_class::ready_again ?= ->
      this.leave?()
      this.leave_clean()
      this.ready?()
      true

    concept_class::select((name) -> name.match(ELEMENT)).each (element, element_class) =>
      @add_element(element, element_class, concept_instance) unless element_class.class_name

  #### PRIVATE ####

  @nullify_on_leave: ->
    this.ACCESSORS.each (name) => this["__#{name}"] = null
    this.each (key, value) =>
      unless not_nullifyable(key, value) || this.READY_ONCE?.includes(key)
        this[key] = null

  @add_element: (element, element_class, concept_instance) =>
    element_class::concept = concept_instance
    element_class.class_name = element_class::class_name = element

    concept_instance.constructor::CONSTANTS.each (name, value) ->
      element_class::[name] = value
    @define_constants(element_class)
    @define_accessors(element_class)
    @unless_defined element_class::document_on, =>
      @define_document_on(element_class::)

  @define_constants: (klass) =>
    constants = @unless_defined klass::constants, =>
      klass::constants().each_with_object {}, (name, value, constants) =>
        @define_constant(klass, name, value, constants)
    klass::CONSTANTS = constants || {}

  @define_constant: (klass, name, value, constants) =>
    if value.class_name
      scope = value.class_name
      scope = value::concept.class_name if scope == 'Element'
      prefix = scope.sub(CLASS_TYPE, '').underscore().upcase()
      shared = name.sub(///#{prefix}_///, '')
      value = if value::?.concept then value::[shared] else value[shared]
    else if value.is_a(Function)
      return @define_constant(klass, name, value(), constants)

    if ['', 'ID', 'CLASS'].includes(value)
      scope = klass::class_name
      scope = klass::concept.class_name if scope == 'Element'
      scope = scope.sub(CLASS_TYPE, '')
      prefixes = @isolate(klass)
      scope = prefixes.concat(scope).join('_') if prefixes.any()
      type = value
      value = "js_#{scope.full_underscore()}_#{name.downcase()}"
      switch type
        when 'ID'
          constants[name] = klass::[name] = "##{value}"
          name = "#{name}_ID"
        when 'CLASS'
          constants[name] = klass::[name] = ".#{value}"
          name = "#{name}_CLASS"

    constants[name] = klass::[name] = value

  @define_accessors: (klass) =>
    accessors = @unless_defined klass::accessors, =>
      klass::accessors().each_with_object [], (name, callback, all) ->
        klass::[name] = -> this["__#{name}"] ?= callback.apply(this, arguments)
        all.push(name)
    klass::ACCESSORS = accessors || []

  @define_document_on: (object) ->
    object.document_on().each_slice(3).each ([events, selector, handler]) ->
      with_target = handler
      handler = (event) ->
        event.preventDefault() if events.start_with('click') && !events.end_with('.continue')
        target = $(event.currentTarget)
        args = Array.prototype.slice.call(arguments)
        args.push(target)
        with_target.apply(this, args)
      if object.document_on_before
        with_before = handler
        handler = ->
          result = object.document_on_before.apply(this, arguments)
          unless result == Js.ABORT
            result = with_before.apply(this, arguments)
          result
      if object.document_on_after
        with_after = handler
        handler = ->
          result = with_after.apply(this, arguments)
          unless result == Js.ABORT
            object.document_on_after.apply(this, arguments)

      $(document).on events, selector, handler

  @isolate: (klass) ->
    prefixes = []
    module_name = (klass::concept || klass::).module_name
    if (isolate = module_name.constantize().isolate)
      isolate = module_name if isolate == true
      prefixes.push isolate
    prefixes

  @unless_defined: (method, definition) ->
    if method? && uniq_methods.excludes(method)
      uniq_methods.push(method)
      definition()

  not_nullifyable = (key, value) ->
    !value? || value.is_a(Function) || key.start_with('__') || key.match(CONSTANT)
