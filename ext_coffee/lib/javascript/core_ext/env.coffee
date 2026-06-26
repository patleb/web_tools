if window.Env?
  console.log "ExtCoffee Overriding #{this.name}.Env"

class window.Env
  @local: process.env.NODE_ENV in ['test', 'development']
  @test: process.env.NODE_ENV is 'test'
  @development: process.env.NODE_ENV is 'development'

  @on_load: ->
    @name = Rails.find('.js_env')?.data('value') ? process.env.NODE_ENV
    this[@name] = true

  @on_ready: (event) ->
    return if event.data.info.once
    Env.on_load()

document.addEventListener 'DOMContentLoaded', Env.on_load
document.addEventListener 'turbolinks:load', Env.on_ready
