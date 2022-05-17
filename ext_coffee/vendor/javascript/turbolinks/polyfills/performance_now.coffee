###
@license http://opensource.org/licenses/MIT
copyright Paul Irish 2015
Added code by Aaron Levine from: https://gist.github.com/Aldlevine/3f716f447322edbb3671
Some modifications by Joan Alba Maldonado.
as Safari 6 doesn't have support for NavigationTiming, we use a Date.now() timestamp for relative values
if you want values similar to what you'd get with real perf.now, place this towards the head of the page
but in reality, you're just getting the delta between now() calls, so it's not terribly important where it's placed
Gist: https://gist.github.com/jalbam/cc805ac3cfe14004ecdf323159ecf40e
###
unless Date.now
  Date.now = () ->
    new Date().getTime()
do ->
  if window.performance and window.performance.now
    return
  window.performance = window.performance ? {}
  if (window.performance.timing and window.performance.timing.navigationStart and
    window.performance.mark and
    window.performance.clearMarks and
    window.performance.getEntriesByName
  )
    window.performance.now = () ->
      window.performance.clearMarks('__PERFORMANCE_NOW__')
      window.performance.mark('__PERFORMANCE_NOW__')
      window.performance.getEntriesByName('__PERFORMANCE_NOW__')[0].startTime
  else if 'now' of window.performance is false
    nowOffset = Date.now()
    if window.performance.timing && window.performance.timing.navigationStart
      nowOffset = window.performance.timing.navigationStart
    window.performance.now = () ->
      Date.now() - nowOffset
  return
