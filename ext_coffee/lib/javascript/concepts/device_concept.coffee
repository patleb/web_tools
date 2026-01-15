### References
# https://codeburst.io/the-only-way-to-detect-touch-with-javascript-7791a3346685
# https://gomakethings.com/the-easy-way-to-manage-css-breakpoints-in-javascript/
# https://code-boxx.com/detect-browser-with-javascript/
###
class Js.DeviceConcept
  global: true

  constants: ->
    SCROLL_X:   'js_device:scroll_x'
    SCROLL_Y:   'js_device:scroll_y'
    RESIZE_X:   'js_device:resize_x'
    RESIZE_Y:   'js_device:resize_y'
    BREAKPOINT: 'js_device:breakpoint'

  ready_once: ->
    @touch = false
    window.addEventListener('touchstart', @on_touchstart, false)
    window.addEventListener('scroll', @on_scroll.throttle(), false)
    window.addEventListener('resize', @on_resize.throttle(), false)
    @screens = JSON.parse(process.env.SCREENS) or { lg: 1024 }
    @screens = @screens.reject((k, v) -> v.is_a Object).each_map((k, v) -> [k, v.to_i()]).to_h()
    @breakpoints = {}
    styles = window.getComputedStyle(document.documentElement, '')
    prefix = try styles.values().join('').match(/-(webkit|moz|ms)-/)?[1]
    @chrome = window.chrome?
    @webkit = not @chrome and prefix is 'webkit'
    @firefox = prefix is 'moz' or typeof InstallTrigger isnt 'undefined'
    @microsoft = prefix is 'ms'
    @opera = prefix is 'o' or (window.opr?.addons?) or window.opera? or navigator.userAgent.include(' OPR/')
    @safari = /constructor/i.test(window.HTMLElement) or ((p) -> p.toString() is '[object SafariRemoteNotification]')(
      not window.safari or (typeof safari isnt 'undefined' and safari.pushNotification)
    )

  ready: ->
    @on_scroll()
    @on_resize()

  on_touchstart: =>
    @touch = true
    window.removeEventListener('touchstart', @on_touchstart, false)

  on_scroll: =>
    @move_was = @move
    @move =
      x: window.scrollX or window.pageXOffset
      y: window.scrollY or window.pageYOffset
    Rails.fire(document, @SCROLL_X) if @move.x isnt @move_was?.x
    Rails.fire(document, @SCROLL_Y) if @move.y isnt @move_was?.y

  on_resize: =>
    @size_was = @size
    @size =
      x: window.innerWidth or document.documentElement.clientWidth or document.body.clientWidth
      y: window.innerHeight or document.documentElement.clientHeight or document.body.clientHeight
    @full_size_was = @full_size
    @full_size =
      x: document.documentElement.scrollWidth or document.body.scrollWidth
      y: document.documentElement.scrollHeight or document.body.scrollHeight
    if @size.x isnt @size_was?.x or @full_size.x isnt @full_size_was?.x
      screen_was = @screen or ((initial = true) and @screens.first()[0])
      included_was = true
      @screens.each (screen, size) =>
        included = @breakpoints[screen] = (@size.x >= size)
        if @screen isnt screen_was and included_was and not included
          @screen = screen_was
          Rails.fire(document, @BREAKPOINT, { initial, @screen })
        screen_was = screen
        included_was = included
      unless @screen
        @screen = @screens.last()[0]
        Rails.fire(document, @BREAKPOINT, { initial, @screen })
      Rails.fire(document, @RESIZE_X)
    if @size.y isnt @size_was?.y or @full_size.y isnt @full_size_was?.y
      Rails.fire(document, @RESIZE_Y)
