window.console ?= {}
for method in ['log', 'trace', 'groupCollapsed', 'groupEnd']
  window.console[method] ?= ->

if window.Logger?
  console.log "ExtCoffee Overriding #{this.name}.Logger"

class window.Logger
  @trace: (@_trace) ->

  @debug: (args...) ->
    if Env.development
      if @_trace
        console.groupCollapsed(args[0])
        console.trace()
        console.groupEnd()
      else
        console.log(args...)
    return

  @now: ->
    console.log Date.current()
