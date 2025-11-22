class Js.RoutesConcept
  global: true

  ready: ->
    @paths = Rails.$('.js_routes').each_with_object {}, (element, memo) =>
      memo.merge(JSON.parse(element.getAttribute('data-value')))

  url_for: (action, params = {}, blanks = true) ->
    return unless path = @paths[action]
    @location(path, params, blanks).href

  path_for: (action, params = {}, blanks = true) ->
    return unless path = @paths[action]
    @location(path, params, blanks).href.sub(/^.*\/\/[^\/]+/, '')

  # NOTE: modern alternative
  # decode_params: (url) ->
  #   return {} unless url.include '?'
  #   Object.fromEntries(new URLSearchParams(url.partition('?').last()))

  decode_params: (string = window.location.search) ->
    params = {}
    data = decodeURIComponent(string).sub(/^\?/, '')
    data.split('&').except('').each (pair) ->
      add_param(params, pair.split('='))
    params

  # Private

  # Anchors not supported
  # Optional /(:variable) segment not supported
  location: (path, params = {}, blanks = true) ->
    params = params.dup()
    location = @decode_url(path)
    pathname = location.pathname.split('/').map (segment) ->
      if segment.start_with ':'
        params.delete(segment.lchop())
      else
        segment
    location.pathname = pathname.join('/').sub(/\/$/, '')
    location.search = params.to_query(blanks) unless params.empty()
    location

  decode_url: (string) ->
    link = document.createElement('a')
    link.href = string
    link

  add_param = (params, [name, value]) ->
    names = name.split('][').map((name) -> name.sub(/\]$/, '').split('[')).flatten()
    [keys..., name] = names.flatten()
    if name.empty()
      name = keys.pop()
      params[name] ?= []
      params[name].push value
    else
      keys.each (key) ->
        params[key] ?= {}
        params = params[key]
      params[name] = value
