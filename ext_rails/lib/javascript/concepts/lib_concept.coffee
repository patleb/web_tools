class Js.LibConcept
  readers: ->
    notice: -> Rails.find('#notice')

  document_on: -> [
    Device.RESIZE_X, document, @clear_drawer_toggle

    'change', '#alert, #notice', (event, target) ->
      @clear_alert(target)
  ]

  ready: ->
    @adjust_autofocus()
    @clear_notice()

  leave: ->
    if @notice()
      clearTimeout(@clear_notice_timeout)
      @clear_alert(@notice())

  clear_drawer_toggle: ->
    if Device.breakpoints_was.lg isnt Device.breakpoints.lg and Device.breakpoints.lg
      Rails.find('.drawer-toggle').set_value(false)

  clear_notice: ->
    if @notice()
      text_size = @notice().nextSibling.firstChild.innerHTML.length || 25
      timeout = text_size * 100
      timeout = 2500 if timeout < 2500
      timeout = 7500 if timeout > 7500
      @clear_notice_timeout = setTimeout(=>
        @clear_alert(@notice())
      , timeout)

  clear_alert: (alert) ->
    alert?.setAttribute('checked', '')

  adjust_autofocus: ->
    Rails.find('[autofocus]:not([type="email"],[type="number"])')?.cursor_end(true)
