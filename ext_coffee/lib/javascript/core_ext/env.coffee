if window.Env?
  console.log "ExtCoffee Overriding #{this.name}.Env"

class window.Env
  @[process.env.NODE_ENV] = true
  @debug: JSON.parse(process.env.LOGGER_DEBUG)
  @trace: JSON.parse(process.env.LOGGER_TRACE)
  @to_s: -> process.env.NODE_ENV
