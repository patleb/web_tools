if window.Env?
  console.log "ExtCoffee Overriding #{this.name}.Env"

class window.Env
  @[process.env.NODE_ENV] = true

  @debug_trace: !!process.env.DEBUG_TRACE

  @to_s: -> process.env.NODE_ENV
