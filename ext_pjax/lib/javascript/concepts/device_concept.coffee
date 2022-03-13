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

    @refresh()
    $(window).on 'resize.device', _.throttle(@refresh)

  on_first_touch: =>
    @touched = true
    window.removeEventListener('touchstart', @on_first_touch, false)

  refresh: =>
    # width = window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth
    # height = window.innerHeight || document.documentElement.clientHeight|| document.body.clientHeight
    @width = @window().width()
    @height = @window().height()
    breakpoint = window.getComputedStyle(@body(), ':before').getPropertyValue('content').gsub(/\"/, '')
    # mobile = (width < 768) || (height < 400)
    @desktop = (breakpoint == 'desktop')
    @mobile = (breakpoint == 'mobile')
    @mini = (breakpoint == 'mini')
