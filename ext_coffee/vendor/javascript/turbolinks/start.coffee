Turbolinks.start = ->
  if install_turbolinks()
    Turbolinks.controller ?= create_controller()
    Turbolinks.controller.start()

install_turbolinks = ->
  window.Turbolinks ?= Turbolinks
  module_is_installed()

create_controller = ->
  controller = new Turbolinks.Controller
  controller.adapter = new Turbolinks.BrowserAdapter(controller)
  controller

module_is_installed = ->
  window.Turbolinks is Turbolinks

Turbolinks.start() if module_is_installed()
