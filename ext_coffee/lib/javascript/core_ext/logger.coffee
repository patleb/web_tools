window.console ?= {}
for method in ['log', 'trace', 'groupCollapsed', 'groupEnd']
  window.console[method] ?= ->

if window.Logger?
  console.log "ExtCoffee Overriding #{this.name}.Logger"

class window.Logger
  @debug: (args...) ->
    if Env.debug or Env.debug isnt false and Env.development
      if Env.trace
        console.groupCollapsed(args[0])
        console.trace()
        console.groupEnd()
      else
        console.log(args...)
    return

  @now: ->
    console.log(new Date(Date.now()))
