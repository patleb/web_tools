class Js.PjaxConcept
  constants: ->
    BODY_ID: 'ID'

  document_on: => [
    'pjax:scroll', Js.Pjax.CONTAINER, (event, pjax, scroll_to, hash) =>
      wrapper = $(Layout.WINDOW)
      scroll_to += wrapper.scrollTop() if hash
      wrapper.scrollTop(scroll_to)
  ]

  ready_once: ->
    Js.Pjax.initialize()
    $('body').addClass('pjax_ready')

  ready: =>
    if (title = $(Js.Pjax.TITLE).data('title'))?.present()
      $(Layout.TITLE).text(title)
    if (body_id = $(@BODY_ID).data('body_id'))?.present()
      $('body').attr(id: body_id)
