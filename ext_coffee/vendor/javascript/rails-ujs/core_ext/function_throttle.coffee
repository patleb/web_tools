### References
# https://github.com/jashkenas/underscore/blob/master/modules/throttle.js
# Returns a function, that, when invoked, will only be triggered at most once
# during a given window of time. Normally, the throttled function will run
# as much as it can, without ever going more than once per `wait` duration;
# but if you'd like to disable the execution on the leading edge, pass
# `{leading: false}`. To disable execution on the trailing edge, ditto.
###
Function.throttle = (fn, wait = 0, options = {}) ->
  if wait is 0
    request = null
    (args...) ->
      request ?= requestAnimationFrame =>
        request = null
        fn.apply(this, args)
  else
    timeout = null; context = null; args = null; result = null
    previous = 0

    later = ->
      previous = if options.leading is false then 0 else Date.now()
      timeout = null
      result = fn.apply(context, args)
      context = args = null unless timeout

    throttled = ->
      _now = Date.now()
      previous = _now if not previous and options.leading is false
      remaining = wait - (_now - previous)
      context = this
      args = arguments
      if remaining <= 0 or remaining > wait
        if timeout
          clearTimeout(timeout)
          timeout = null
        previous = _now
        result = fn.apply(context, args)
        context = args = null unless timeout
      else if not timeout and options.trailing isnt false
        timeout = setTimeout(later, remaining)
      result

    throttled.cancel = ->
      clearTimeout(timeout)
      previous = 0
      timeout = context = args = null

Function::throttle = (wait = 0, options = {}) ->
  @constructor.throttle(this, wait, options)

Object.defineProperty(Function::, 'throttle', enumerable: false)
