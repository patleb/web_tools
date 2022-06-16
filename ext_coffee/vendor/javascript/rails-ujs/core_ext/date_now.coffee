unless Date.now
  Date.now = ->
    new Date().getTime()
