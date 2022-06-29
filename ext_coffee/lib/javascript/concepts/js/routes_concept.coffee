class Js.RoutesConcept
  global: true

  constants: ->
    ROUTES: '.js_routes'
    PATHS: 'data-paths'

  ready: ->
    @paths = Rails.$(@ROUTES).each_with_object {}, (element, memo) =>
      memo.merge(JSON.parse(element.getAttribute(@PATHS)))

  url_for: (action, params = {}) ->
    @location(action, params).href

  path_for: (action, params = {}) ->
    @location(action, params).href.sub(/^.*\/\/[^\/]+/, '')

  # Optional /(:variable) segment not supported
  location: (action, params = {}) ->
    params = params.dup()
    location = @decode_url(@paths[action])
    pathname = location.pathname.split('/').map (segment) ->
      if segment.start_with ':'
        params.delete(segment.lchop())
      else
        segment
    location.pathname = pathname.join('/').sub(/\/$/, '')
    location.search = @encode_params(params) unless params.empty()
    location

  decode_url: (string) ->
    link = document.createElement('a')
    link.href = string
    link

  # Object of Arrays and Array of Objects not supported
  encode_params: (params) ->
    params = params.map (param_name, param_value) ->
      switch param_value?.constructor
        when Object
          param_value.flatten_keys('][').map (names, value) ->
            [[param_name, '[', names, ']'].join(''), value]
        when Array
          param_value.map (value) ->
            [[param_name, '[]'].join(''), value]
        else
          [[param_name, param_value]]
    params = params.map (values) ->
      values.map ([name, value]) -> "#{encodeURIComponent(name)}=#{encodeURIComponent(value)}"
    params.flatten().join('&')

  decode_params: (string) ->
    params = {}
    data = decodeURIComponent(string).sub(/^\?/, '')
    data.split('&').except('').each (pair) ->
      add_param(params, pair.split('='))
    params

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
