class Turbolinks.Snapshot
  @wrap: (value) ->
    if value instanceof this
      value
    else if typeof value is 'string'
      @from_string(value)
    else
      @from_element(value)

  @from_string: (html) ->
    { documentElement } = new DOMParser().parseFromString(html, 'text/html')
    @from_element(documentElement)

  @from_element: (element) ->
    head = element.querySelector('head')
    body = element.querySelector('body') ? document.createElement('body')
    head_details = Turbolinks.HeadDetails.from_element(head)
    new this head_details, body

  constructor: (@head_details, @body) ->

  clone: ->
    { body } = @constructor.from_string(@body.outerHTML)
    new @constructor @head_details, body

  get_root_location: ->
    root = @get_setting('root') ? '/'
    new Turbolinks.Location(root)

  get_anchor: (name) ->
    return @body if name == ''
    try @body.querySelector("[id='#{name}'], a[name='#{name}']")

  get_permanent: (element) ->
    @body.querySelector("##{element.id}[data-turbolinks-permanent]")

  get_permanent_elements: (snapshot) ->
    element for element in @body.querySelectorAll('[id][data-turbolinks-permanent]') when snapshot.get_permanent(element)

  first_autofocusable: ->
    @body.querySelector('[autofocus]')

  has_anchor: (name) ->
    @get_anchor(name)?

  is_previewable: ->
    @get_setting('cache-control') isnt 'no-preview'

  is_cacheable: ->
    Turbolinks.Controller.cache_size and @get_setting('cache-control') isnt 'no-cache'

  is_visitable: ->
    @get_setting('visit-control') isnt 'reload'

  is_scrollable: ->
    @get_setting('visit-control') isnt 'no-scroll'

  # Private

  get_setting: (name) ->
    @head_details.get_meta_value("turbolinks-#{name}")
