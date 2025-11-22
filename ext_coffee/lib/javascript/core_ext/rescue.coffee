if process.env.NODE_ENV is 'production'
  window.rescues_caught = []
  window.rescues_ignored = []
  window.addEventListener 'error', (event) ->
    if rescues_ignored.find(string -> event.message?.include(string))
      Logger.debug(event.message)
    else
      rescue = { message: event.message, backtrace: [event.values_at(['filename', 'lineno', 'colno']...).join(':')] }
      rescue_string = JSON.stringify(rescue)
      if rescues_caught.exclude(rescue_string)
        rescues_caught.push(rescue_string)
        XHR.send(url: '/_rescue_js', type: 'POST', data_type: 'json', data: { rescue_js: rescue })
    Rails.stop_everything(event)
