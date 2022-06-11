window.console ?= {}
for method in ['log', 'trace', 'groupCollapsed', 'groupEnd']
  window.console[method] ?= ->

if window.Logger?
  console.log "ExtCoffee Overriding #{this.name}.Logger"

class window.Logger
  @ignored_methods: {}

  @warn_define_method: (klass, name) =>
    if klass::[name]
      klass_name = klass.class_name or klass.name
      unless (ignored = @ignored_methods[klass_name]) and ignored[name]
        @debug "ExtCoffee Overriding #{klass_name}.prototype.#{name}"

  @warn_define_singleton_method: (klass, name) =>
    if klass[name]
      klass_name = klass.class_name or klass.name or klass.constructor.name
      @debug "ExtCoffee Overriding #{klass_name}.#{name}"

  @debug: (args...) ->
    if Env.development
      if Env.debug_trace
        console.groupCollapsed(args[0])
        console.trace()
        console.groupEnd()
      else
        console.log(args...)
    true

  @now: ->
    console.log(new Date(Date.now()))
