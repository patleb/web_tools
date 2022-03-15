### References
# https://codeburst.io/the-only-way-to-detect-touch-with-javascript-7791a3346685
# https://gomakethings.com/the-easy-way-to-manage-css-breakpoints-in-javascript/
###
class Js.DeviceConcept
  global: true

  accessors: ->
    window: -> $(window)
    body:   -> document.querySelector('body')

  ready_once: =>
    @touched = false
    window.addEventListener('touchstart', @on_first_touch, false)

    @screens = JSON.parse(process.env.SCREENS) || { sm: 640, md: 768, lg: 1024, xl: 1280, '2xl': 1536 }
    @screens = @screens.map((k, v) -> [k, v.to_i()]).to_h()
    @refresh()
    $(window).on 'resize.device', _.throttle(@refresh)

  on_first_touch: =>
    @touched = true
    window.removeEventListener('touchstart', @on_first_touch, false)

  refresh: =>
    @width = @window().width()
    @height = @window().height()

    @desktop = (@width >= @screens.md)
    @mobile = (@width < @screens.md) || (@height <= @screens.sm / 2)
    @mini = (@width <= @screens.sm / 2)
