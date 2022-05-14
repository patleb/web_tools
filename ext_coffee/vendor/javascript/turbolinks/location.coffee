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

    anchor_length = link.hash.length
    if anchor_length < 2
      @request_url = @absolute_url
    else
      @request_url = @absolute_url.slice(0, -anchor_length)
      @anchor = link.hash.slice(1)

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

  is_html: ->
    !!@get_extension().match(/^(?:|\.(?:htm|html|xhtml))$/)

  is_prefixed_by: (location) ->
    prefix_url = get_prefix_url(location)
    @is_equal_to(location) or string_starts_with(@absolute_url, prefix_url)

  is_equal_to: (location) ->
    @absolute_url is location?.absolute_url

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
