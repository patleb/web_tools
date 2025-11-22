class Js.Admin.SearchConcept
  DATE = /[0-9]{4}-[0-9]{2}-[0-9]{2}/

  readers: ->
    query_bar: -> Rails.find('.js_query_bar')
    search: -> Rails.find('.js_search')

  events: -> [
    'search', '.js_search', @on_blank_search

    'turbolinks:submit', '.js_query_bar', ->
      @query_submitted = true

    'change', '.js_query_datetime', (event, target) ->
      @with_search_token(target, (before, token) =>
        if @is_after_operator(before)
          token
        else if @is_after_separator(before)
          "=#{token}"
        else if target.type is 'time'
          if before.last() is 'T'
            token
          else if before.match DATE
            "T#{token}"
      , reset: true, before_size: 10)

    'change', '.js_query_keyword', (event, target) ->
      @with_search_token(target, (before, token) =>
        if @is_after_operator(before, equality_only: true)
          token
        else if @is_after_separator(before)
          "=#{token}"
      , reset: true)

    'change', '.js_query_operator', (event, target) ->
      @with_search_token(target, (before, token) =>
        token if @is_after_separator(before)
      , reset: true)

    'click', '.js_query_or', (event, target) ->
      @with_search_token(target, (before, token) =>
        token unless @is_after_operator(before) or @is_after_separator(before)
      , token: '|')

    'click', '.js_query_and', (event, target) ->
      @with_search_token(target, (before, token) =>
        return token if before.end_with(' ')
        " #{token}" unless @is_after_operator(before) or @is_after_separator(before)
      , token: '{_}')

    'click', '.js_query_field', (event, target) ->
      @with_search_token(target, (before, token) =>
        return if before is '_}' or @is_after_operator(before)
        switch before.last() ? ''
          when '', ' ' then "{#{token}}"
          when '{'     then token
          when '}'     then { reopen: true, result: "|#{token}}" }
          when '|' # do nothing
          else " {#{token}}"
      , token: target.data('field'))
  ]

  ready: ->
    @query_submitted = false

  # Private

  on_blank_search: (event, target) ->
    return if @query_submitted
    return if target.get_value()?.present()
    return unless Routes.decode_params().q
    @query_bar.fire 'submit'

  with_search_token: (target, callback, { reset = false, before_size = 2, token = target.get_value() } = {}) ->
    search = @search.get_value() ? ''
    cursor_end = @search.cursor_end()
    cursor_start = cursor_end - before_size
    cursor_start = 0 if cursor_start < 0
    before = search[cursor_start...cursor_end] or search[cursor_end - 1] ? ''
    token = callback(before, token)
    if token?.reopen
      search = search.insert(cursor_end - 1, token.result, replace: 1)
      move = cursor_end - 1 + token.result.size()
    else if token
      search = search.insert(cursor_end, token)
      move = cursor_end + token.size()
    else
      move = cursor_end
    target.set_value('') if reset # otherwise can't reuse the same value, the 'change' event won't fire
    @search.set_value(search)
    @search.focus()
    @search.cursor_end(move)

  is_after_operator: (before, { equality_only = false } = {}) ->
    if equality_only
      before.last(2)?.match /[=!]=?$/
    else
      before.last(2)?.match /[=!<>]=?$/

  is_after_separator: (before) ->
    before is '' or before.match /[ }|]$/
