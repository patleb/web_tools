class Turbolinks.Snapshot
  @wrap: (value) ->
    if value instanceof this
      value
    else if typeof value is 'string'
      @from_string(value)
    else
      @from_element(value)

  @from_string: (html) ->
    return @from_element(html) if html instanceof HTMLDocument
    { documentElement } = new DOMParser().parseFromString(html, 'text/html')
    @from_element(documentElement)

  @from_element: (element) ->
    html_tag = Array.wrap(element.attributes).map ({ name, value }) -> [name, value]
    head = element.querySelector('head')
    body = element.querySelector('body') ? document.createElement('body')
    head_details = new Turbolinks.HeadDetails(head)
    new this html_tag, head_details, body

  constructor: (@html_tag, @head_details, @body) ->

  clone: ->
    { body } = @constructor.from_string(@body.outerHTML)
    new @constructor @html_tag, @head_details, body

  get_root_location: ->
    root = @head_details.get_meta_value('turbolinks-root') ? '/'
    new Turbolinks.Location(root)

  get_anchor: (name) ->
    return @body if name is ''
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
    @head_details.get_meta_value('turbolinks-cache-control') isnt 'no-preview'

  is_cacheable: ->
    Turbolinks.Controller.cache_size and @head_details.get_meta_value('turbolinks-cache-control') isnt 'no-cache'

  is_visitable: ->
    @head_details.get_meta_value('turbolinks-visit-control') isnt 'reload'

  is_scrollable: ->
    @head_details.get_meta_value('turbolinks-visit-control') isnt 'no-scroll'
