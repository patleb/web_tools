class Turbolinks.Location
  @current_location: ->
    @wrap(window.location)

  @wrap: (value) ->
    if value instanceof this
      value
    else
      new this value

  constructor: (url = '') ->
    link = document.createElement('a')
    link.href = url.toString()

    @absolute_url = link.href

    if hash = @absolute_url.hash
      @anchor = hash.slice(1)
    else if anchor_match = @absolute_url.match(/#(.*)$/)
      @anchor = anchor_match[1]
    if @anchor?
      @request_url = @absolute_url.slice(0, -(@anchor.length + 1))
    else
      @request_url = @absolute_url

  push_query: (string) ->
    if @has_query()
      @request_url += "&#{string.replace(/^&/, '')}"
    else
      @request_url += "?#{string.replace(/^\?/, '')}"
    if @anchor?
      @absolute_url = "#{@request_url}##{@anchor}"
    else
      @absolute_url = @request_url

  get_origin: ->
    @absolute_url.split('/', 3).join('/')

  get_path: ->
    @request_url.match(/\/\/[^/]*(\/[^?;]*)/)?[1] ? '/'

  get_path_components: ->
    @get_path().split('/').slice(1)

  get_last_path_component: ->
    @get_path_components().slice(-1)[0]

  get_extension: ->
    @get_last_path_component().match(/\.[^.]*$/)?[0] ? ''

  has_query: ->
    @request_url.indexOf('?') isnt -1

  is_html: ->
    !!@get_extension().match(/^(?:|\.(?:htm|html|xhtml))$/)

  is_prefixed_by: (location) ->
    prefix_url = get_prefix_url(location)
    @is_equal_to(location) or string_starts_with(@absolute_url, prefix_url)

  is_equal_to: (location) ->
    @absolute_url is location?.absolute_url

  is_same_page: ->
    @request_url is @constructor.current_location().request_url

  to_cache_key: ->
    @request_url

  # Standard interface

  toJSON: ->
    @absolute_url

  toString: ->
    @absolute_url

  valueOf: ->
    @absolute_url

  # Private

  get_prefix_url = (location) ->
    add_trailing_slash(location.get_origin() + location.get_path())

  add_trailing_slash = (url) ->
    if string_ends_with(url, '/') then url else url + '/'

  string_starts_with = (string, prefix) ->
    string.slice(0, prefix.length) is prefix

  string_ends_with = (string, suffix) ->
    string.slice(-suffix.length) is suffix
