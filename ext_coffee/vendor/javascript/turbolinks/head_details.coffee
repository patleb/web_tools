class Turbolinks.HeadDetails
  constructor: (@head) ->
    nodes = @head?.childNodes ? []
    @elements = {}
    for node in nodes when node.nodeType is Node.ELEMENT_NODE and node.tagName.downcase() isnt 'noscript'
      if node.hasAttribute('nonce')
        node.setAttribute('nonce', '')
      key = node.outerHTML
      data = @elements[key] ?=
        type: type_of(node)
        tracked: is_tracked(node)
        elements: []
      data.elements.push(node)

  has_key: (key) ->
    key of @elements

  get_tracked_signature: ->
    (key for key, { tracked } of @elements when tracked).join('')

  get_missing_scripts: (head_details) ->
    @get_missing_elements('script', head_details)

  get_missing_stylesheets: (head_details) ->
    @get_missing_elements('stylesheet', head_details)

  get_missing_elements: (node_type, head_details) ->
    elements[0] for key, { type, elements } of @elements when type is node_type and not head_details.has_key(key)

  get_provisional_elements: ->
    result = []
    for key, { type, tracked, elements } of @elements
      if not type? and not tracked
        result.push(elements...)
      else if elements.length > 1
        result.push(elements[1...]...)
    result

  get_meta_value: (name) ->
    element = undefined
    for key, { elements } of @elements
      if is_meta_with(elements[0], name)
        element = elements[0]
    element?.getAttribute('content')

  type_of = (element) ->
    if is_script(element)
      'script'
    else if is_stylesheet(element)
      'stylesheet'

  is_tracked = (element) ->
    element.getAttribute('data-turbolinks-track') is 'reload'

  is_script = (element) ->
    tagName = element.tagName.downcase()
    tagName is 'script'

  is_stylesheet = (element) ->
    tagName = element.tagName.downcase()
    tagName is 'style' or (tagName is 'link' and element.getAttribute('rel') in ['stylesheet', 'preload'])

  is_meta_with = (element, name) ->
    tagName = element.tagName.downcase()
    tagName is 'meta' and element.getAttribute('name') is name
