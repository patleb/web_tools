### References
# https://codeburst.io/the-only-way-to-detect-touch-with-javascript-7791a3346685
# https://gomakethings.com/the-easy-way-to-manage-css-breakpoints-in-javascript/
# https://code-boxx.com/detect-browser-with-javascript/
###
class Js.DeviceConcept
  global: true

  ready_once: ->
    @touched = false
    window.addEventListener('touchstart', @on_touchstart, false)

    @screens = JSON.parse(process.env.SCREENS) or { md: 768 }
    @screens = @screens.reject((k, v) -> v.is_a Object).map((k, v) -> [k, v.to_i()]).to_h()
    @on_resize()
    window.addEventListener('resize', @on_resize.throttle(), false)

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

  on_touchstart: =>
    @touched = true
    window.removeEventListener('touchstart', @on_touchstart, false)

  on_resize: =>
    @width = window.innerWidth or document.documentElement.clientWidth or document.body.clientWidth
    @height = window.innerHeight or document.documentElement.clientHeight or document.body.clientHeight
    @mobile = (@width < @screens.md)
