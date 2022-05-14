{ defer, dispatch } = Turbolinks

handle_event = (name, handler) ->
  document.addEventListener(name, handler, false)

translate_event = ({ from, to }) ->
  handler = (event) ->
    event = dispatch(to, target: event.target, cancelable: event.cancelable, data: event.data)
    event.preventDefault() if event.defaultPrevented
  handle_event(from, handler)

translate_event from: 'turbolinks:click', to: 'page:before-change'
translate_event from: 'turbolinks:request-start', to: 'page:fetch'
translate_event from: 'turbolinks:request-end', to: 'page:receive'
translate_event from: 'turbolinks:before-cache', to: 'page:before-unload'
translate_event from: 'turbolinks:render', to: 'page:update'
translate_event from: 'turbolinks:load', to: 'page:change'
translate_event from: 'turbolinks:load', to: 'page:update'

loaded = false
handle_event 'DOMContentLoaded', ->
  defer ->
    loaded = true
handle_event 'turbolinks:load', ->
  if loaded
    dispatch('page:load')

jQuery?(document).on 'ajaxSuccess', (event, xhr, settings) ->
  if jQuery.trim(xhr.responseText).length > 0
    dispatch('page:update')
