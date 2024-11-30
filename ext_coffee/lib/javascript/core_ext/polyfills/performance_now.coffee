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
unless window.performance?.now
  window.performance ?= {}
  if performance.timing?.navigationStart and performance.mark and performance.clearMarks and performance.getEntriesByName
    performance.now = ->
      performance.clearMarks('__PERFORMANCE_NOW__')
      performance.mark('__PERFORMANCE_NOW__')
      performance.getEntriesByName('__PERFORMANCE_NOW__')[0].startTime
  else if 'now' not of performance
    nowOffset = Date.now()
    if performance.timing?.navigationStart
      nowOffset = performance.timing.navigationStart
    performance.now = ->
      Date.now() - nowOffset
