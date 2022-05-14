class Turbolinks.ErrorRenderer extends Turbolinks.Renderer
  constructor: (html) ->
    super()
    element = document.createElement('html')
    element.innerHTML = html
    @new_head = element.querySelector('head')
    @new_body = element.querySelector('body')

  render: (callback) ->
    @render_view =>
      { head, body } = document
      head.parentNode.replaceChild(@new_head, head)
      body.parentNode.replaceChild(@new_body, body)
      for element in document.documentElement.querySelectorAll('script')
        script = @create_script(element)
        element.parentNode.replaceChild(script, element)
      callback()
