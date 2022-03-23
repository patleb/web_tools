### References
# https://codeburst.io/the-only-way-to-detect-touch-with-javascript-7791a3346685
# https://gomakethings.com/the-easy-way-to-manage-css-breakpoints-in-javascript/
# https://code-boxx.com/detect-browser-with-javascript/
###
class Js.DeviceConcept
  global: true

  accessors: ->
    window: -> $(window)

  ready_once: =>
    @touched = false
    window.addEventListener('touchstart', @on_first_touch, false)

    @screens = JSON.parse(process.env.SCREENS) || { md: 768 }
    @screens = @screens.reject((k, v) -> v.is_a(Object)).map((k, v) -> [k, v.to_i()]).to_h()
    @refresh()
    $(window).on 'resize.device', _.throttle(@refresh)

    prefix = window.getComputedStyle(document.documentElement, '').vals().join('').match(/-(webkit|moz|ms)-/)[1].downcase()
    @webkit = prefix == 'webkit'
    @firefox = prefix == 'moz' || typeof InstallTrigger != 'undefined'
    @microsoft = prefix == 'ms'
    @chrome = !!window.chrome
    @opera = prefix == 'o' || (!!window.opr && !!opr.addons) || !!window.opera || navigator.userAgent.includes(' OPR/')
    @safari = /constructor/i.test(window.HTMLElement) || ((p) -> p.toString() == "[object SafariRemoteNotification]")(
      !window['safari'] || (typeof safari != 'undefined' && safari.pushNotification)
    )

  on_first_touch: =>
    @touched = true
    window.removeEventListener('touchstart', @on_first_touch, false)

  refresh: =>
    @width = @window().width()
    @height = @window().height()
    @phone = (@width < @screens.md)
