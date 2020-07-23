class Js.RoutesConcept
  global: true

  constants: ->
    PATHS: 'ID'

  ready_once: =>
    @routes = $(@PATHS).data('paths')

  url_for: (action, params = {}) =>
    location = $.parse_location(@routes[action])
    remaining_params = {}
    params.each (name, value) ->
      segment = "__#{name.upcase()}__"
      if location.pathname.includes(segment)
        location.pathname = location.pathname.sub(segment, value)
      else
        remaining_params[name] = value
    location.search = $.param(remaining_params)
    location.href

  path_for: (action, params = {}) =>
    url = @url_for(action, params)
    $.parse_location(url).pathname
