class Turbolinks.Renderer
  @render: (controller, callback, args...) ->
    renderer = new this args...
    renderer.controller = controller
    renderer.render(callback)
    renderer

  render_view: (callback) ->
    @controller.view_will_render(@new_body)
    callback()
    @controller.view_rendered(@new_body)

  create_script: (element) ->
    if element.getAttribute('data-turbolinks-eval') is 'false'
      element
    else
      script = document.createElement('script')
      script.textContent = element.textContent
      script.nonce = element.nonce if element.nonce
      script.async = false
      for { name, value } in element.attributes
        script.setAttribute(name, value)
      script
