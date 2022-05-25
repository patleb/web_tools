###
requestAnimationFrame polyfill by Erik Möller.
Fixes from Paul Irish, Tino Zijdel, Andrew Mao, Klemen Slavic, Darius Bacon and Joan Alba Maldonado.
Adapted from https://gist.github.com/paulirish/1579671 which derived from
http://paulirish.com/2011/requestanimationframe-for-smart-animating/
http://my.opera.com/emoller/blog/2011/12/20/requestanimationframe-for-smart-er-animating
Added high resolution timing. This window.performance.now() polyfill can be used: https://gist.github.com/jalbam/cc805ac3cfe14004ecdf323159ecf40e
MIT license
Gist: https://gist.github.com/jalbam/5fe05443270fa6d8136238ec72accbc0
###
do ->
  vendors = ['webkit', 'moz', 'ms', 'o']
  for vp in vendors when not window.requestAnimationFrame and not window.cancelAnimationFrame
    window.requestAnimationFrame = window.requestAnimationFrame or window["#{vp}RequestAnimationFrame"]
    window.cancelAnimationFrame = window.cancelAnimationFrame or window["#{vp}CancelAnimationFrame"] or window["#{vp}CancelRequestAnimationFrame"]

  if /iP(ad|hone|od).*OS 6/.test(window.navigator.userAgent) or not window.requestAnimationFrame or not window.cancelAnimationFrame
    lastTime = 0
    window.requestAnimationFrame = (callback, element) ->
      now = window.performance.now()
      nextTime = Math.max(lastTime + 16, now)
      setTimeout(() ->
        callback(lastTime = nextTime)
      , nextTime - now)
    window.cancelAnimationFrame = clearTimeout;
  return
