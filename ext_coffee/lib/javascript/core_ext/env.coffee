if window.Env?
  console.log "ExtCoffee Overriding #{this.name}.Env"

class window.Env
  @[process.env.NODE_ENV] = true
  @local: process.env.NODE_ENV is 'test' or process.env.NODE_ENV is 'development'
  @to_s: -> process.env.NODE_ENV
