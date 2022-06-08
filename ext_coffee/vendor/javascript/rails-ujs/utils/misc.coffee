id = 0

window.Rails = Rails.merge
  uid: ->
    pad = '0000000000000'
    time = (new Date().getTime()).toString()
    time = String(time + pad).substring(0, pad.length)
    pad = '000'
    num = id++
    num = String(pad + num).slice(-pad.length)
    "#{time}#{num}"

  uuid: ->
    result = ''
    for i in [1..36]
      if i in [9, 14, 19, 24]
        result += '-'
      else if i is 15
        result += '4'
      else if i is 20
        result += (Math.floor(Math.random() * 4) + 8).toString(16)
      else
        result += Math.floor(Math.random() * 15).toString(16)
    result
