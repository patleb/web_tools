if window.Env?
  console.log "ExtCoffee Overriding #{this.name}.Env"

class window.Env
  @current: process.env.NODE_ENV
  @debug_trace: !!process.env.DEBUG_TRACE

  @initialize: =>
    for env in ['development', 'test', 'vagrant', 'staging', 'production']
      @[env] = @is(env)

  @is: (env) =>
    @current == env

window.Env.initialize()
