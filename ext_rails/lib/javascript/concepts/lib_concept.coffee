class Js.LibConcept extends Js.Base
  @readers
    role: -> Cookie.get('_role') ? 'null'

  readers: ->
    layout:   -> Rails.find('.js_layout')?.data('value')
    scroll_y: -> @layout and @sidebar and @store('scroll_y')?["#{@role}_#{@layout}"]
    sidebar:  -> Rails.find('.drawer-side')
    notice:   -> Rails.find('#notice')

  events: -> [
    Device.BREAKPOINT, document, @clear_drawer_toggle

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
    @clear_flash(@notice)

  restore_sidebar_scroll: ->
    if (scroll_y = @scroll_y)
      @sidebar.scrollTop = scroll_y.top * (@sidebar.clientHeight / scroll_y.height)

  persist_sidebar_scroll: ->
    if @layout and @sidebar
      scroll_y = { top: @sidebar.scrollTop, height: @sidebar.clientHeight }
      stored_scroll_y = @store('scroll_y') ? {}
      @store('scroll_y', stored_scroll_y.merge("#{@role}_#{@layout}": scroll_y))

  clear_drawer_toggle: ->
    Rails.find('.drawer-toggle')?.set_value(false) if Device.screen is 'lg'

  clear_notice: ->
    if @notice
      timeout = Flash.timeout_for(@notice.nextSibling.firstChild.innerHTML)
      @clear_notice_timeout = setTimeout(=>
        @clear_flash(@notice)
      , timeout)

  clear_flash: (target) ->
    target?.setAttribute('checked', '')

  adjust_autofocus: ->
    Rails.find('[autofocus]:not([type="email"],[type="number"],[type="range"])')?.cursor_end(true)
