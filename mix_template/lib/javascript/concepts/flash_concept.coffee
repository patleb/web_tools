class Js.FlashConcept
  global: true

  constants: ->
    MESSAGES: 'ID'
    WRAPPER: 'CLASS'
    DISMISS: '.alert-info:visible, .alert-success:visible'

  document_on: => [
    'pjax:clone', Js.Pjax.CONTAINER, (event, pjax, contents) =>
      contents.each$ (content) =>
        content.find_all(@MESSAGES).attr('data-messages': [])
  ]

  ready: =>
    return unless (messages = $(@MESSAGES)).length

    @clear()
    messages.data('messages').each ([type, message]) =>
      @render(type, message, false)
    messages.data(messages: [])
    @auto_dismiss()

  error: (message) =>
    $(@MESSAGES).data(messages: [['error', message]])
    this

  render: (type, message, clear = true) =>
    @clear() if clear
    $(Js.Pjax.CONTAINER).prepend(
      div_ @WRAPPER, class: "alert alert-dismissible #{@alert_class(type)}", [
        button_ '×', type: 'button', class: 'close', data: { dismiss: 'alert' }
        message.html_safe(true)
      ]
    )

  clear: =>
    $(@WRAPPER).remove()

  #### PRIVATE ####

  alert_class: (type) ->
    switch type
      when 'error'  then 'alert-danger'
      when 'alert'  then 'alert-warning'
      when 'notice' then 'alert-info'
      else "alert-#{type}"

  auto_dismiss: =>
    $(@DISMISS).fadeTo(3000, 500).slideUp(500)
