id = 0

Math.uid = ->
  pad = '0000000000000'
  time = Date.now().toString()
  time = String(time + pad).substring(0, pad.length)
  pad = '000'
  num = id++
  num = String(pad + num).slice(-pad.length)
  "#{time}#{num}"
