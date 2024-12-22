class Js.LibConcept
  readers: ->
    scroll_y: -> @sidebar() and @store('scroll_y')
    sidebar: -> Rails.find('.drawer-side')
    notice: -> Rails.find('#notice')

  document_on: -> [
    Device.RESIZE_X, document, @clear_drawer_toggle

    'change', '#alert, #notice', (event, target) ->
      @clear_flash(target)
  ]

  ready: ->
    @restore_sidebar_scroll()
    @adjust_autofocus()
    @clear_notice()

  leave: ->
    @persist_sidebar_scroll()
    clearTimeout(@clear_notice_timeout)
    @clear_flash(@notice())

  restore_sidebar_scroll: ->
    if (scroll_y = @scroll_y())
      @sidebar().scrollTop = scroll_y.top * (@sidebar().clientHeight / scroll_y.height)

  persist_sidebar_scroll: ->
    if @sidebar()
      scroll_y = { top: @sidebar().scrollTop, height: @sidebar().clientHeight }
      @store('scroll_y', scroll_y)

  clear_drawer_toggle: ->
    if Device.breakpoints_was.lg isnt Device.breakpoints.lg and Device.breakpoints.lg
      Rails.find('.drawer-toggle').set_value(false)

  clear_notice: ->
    if @notice()
      timeout = Flash.timeout_for(@notice().nextSibling.firstChild.innerHTML)
      @clear_notice_timeout = setTimeout(=>
        @clear_flash(@notice())
      , timeout)

  clear_flash: (target) ->
    target?.setAttribute('checked', '')

  adjust_autofocus: ->
    Rails.find('[autofocus]:not([type="email"],[type="number"])')?.cursor_end(true)
