### References
# https://codeburst.io/the-only-way-to-detect-touch-with-javascript-7791a3346685
# https://gomakethings.com/the-easy-way-to-manage-css-breakpoints-in-javascript/
# https://code-boxx.com/detect-browser-with-javascript/
###
class Js.DeviceConcept
  global: true

  constants: ->
    RESIZE_X: 'js_device:resize_x'
    RESIZE_Y: 'js_device:resize_y'
    MOBILE:   'js_device:mobile'
    SCROLL_X: 'js_device:scroll_x'
    SCROLL_Y: 'js_device:scroll_y'

  ready_once: ->
    @touched = false
    window.addEventListener('touchstart', @on_touchstart, false)

    @screens = JSON.parse(process.env.SCREENS) or { md: 768 }
    @screens = @screens.reject((k, v) -> v.is_a Object).map((k, v) -> [k, v.to_i()]).to_h()
    window.addEventListener('resize', @on_resize.throttle(), false)
    window.addEventListener('scroll', @on_scroll.throttle(), false)

    styles = window.getComputedStyle(document.documentElement, '')
    prefix = try styles.values().join('').match(/-(webkit|moz|ms)-/)?[1]
    @webkit = prefix is 'webkit'
    @firefox = prefix is 'moz' or typeof InstallTrigger isnt 'undefined'
    @microsoft = prefix is 'ms'
    @chrome = window.chrome?
    @opera = prefix is 'o' or (window.opr?.addons?) or window.opera? or navigator.userAgent.include(' OPR/')
    @safari = /constructor/i.test(window.HTMLElement) or ((p) -> p.toString() is '[object SafariRemoteNotification]')(
      not window.safari or (typeof safari isnt 'undefined' and safari.pushNotification)
    )

  ready: ->
    @on_resize()
    @on_scroll()

  on_touchstart: =>
    @touched = true
    window.removeEventListener('touchstart', @on_touchstart, false)

  on_resize: =>
    @size_was = @size
    @size =
      x: window.innerWidth or document.documentElement.clientWidth or document.body.clientWidth
      y: window.innerHeight or document.documentElement.clientHeight or document.body.clientHeight
    @full_size_was = @full_size
    @full_size =
      x: document.documentElement.scrollWidth or document.body.scrollWidth
      y: document.documentElement.scrollHeight or document.body.scrollHeight
    @mobile_was = @mobile
    @mobile = (@size.x < @screens.md)
    Rails.fire(document, @RESIZE_X) if @size.x isnt @size_was?.x
    Rails.fire(document, @RESIZE_Y) if @size.y isnt @size_was?.y
    Rails.fire(document, @MOBILE) if @mobile isnt @mobile_was

  on_scroll: =>
    @move_was = @move
    @move =
      x: window.scrollX or window.pageXOffset
      y: window.scrollY or window.pageYOffset
    Rails.fire(document, @SCROLL_X) if @move.x isnt @move_was?.x
    Rails.fire(document, @SCROLL_Y) if @move.y isnt @move_was?.y
