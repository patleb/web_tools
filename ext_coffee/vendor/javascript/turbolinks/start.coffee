Turbolinks.start = ->
  if install_turbolinks()
    Turbolinks.controller ?= new Turbolinks.Controller
    Turbolinks.controller.start()

install_turbolinks = ->
  window.Turbolinks ?= Turbolinks
  module_is_installed()

module_is_installed = ->
  window.Turbolinks is Turbolinks

Turbolinks.start() if module_is_installed()
