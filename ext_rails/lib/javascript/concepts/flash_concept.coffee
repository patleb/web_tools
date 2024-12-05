class Js.FlashConcept
  global: true

  readers: ->
    header: -> Rails.find('#header')

  document_on: -> [
    'change', '#js_error, #js_info', (event, target) ->
      @clear_flash(target)
  ]

  leave: ->
    @clear_notice()

  timeout_for: (message) ->
    timeout = (message.length || 25) * 100
    timeout = 2500 if timeout < 2500
    timeout = 7500 if timeout > 7500
    timeout

  error: (message) ->
    @header().append @flash_message('error', message)...
    message

  info: (message) ->
    @clear_notice()
    @header().append @flash_message('info', message)...
    timeout = @timeout_for(message)
    @clear_notice_timeout = setTimeout(=>
      @clear_flash(@notice())
    , timeout)
    message

  # Private

  notice: ->
    Rails.find('#js_info')

  flash_message: (key, message) ->
    [
      input$ id: "js_#{key}", type: 'checkbox'
      div$ '.alert.shadow-xl', class: "alert-#{key}", -> [
        span_ message.simple_format()
        label_ '.btn.btn-circle.btn-xs', '&times;'.html_safe(true), for: "js_#{key}"
      ]
    ]

  clear_notice: ->
    clearTimeout(@clear_notice_timeout)
    @clear_flash(@notice())

  clear_flash: (target) ->
    target?.nextSibling?.remove()
    target?.remove()
