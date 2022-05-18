class Turbolinks.SnapshotRenderer extends Turbolinks.Renderer
  constructor: (@old_snapshot, @new_snapshot, @is_preview) ->
    super()
    @old_head_details = @old_snapshot.head_details
    @new_head_details = @new_snapshot.head_details
    @old_body = @old_snapshot.body
    @new_body = @new_snapshot.body

  render: (callback) ->
    if not @new_snapshot.is_visitable()
      @controller.page_invalidated('turbolinks_visit_control_is_reload')
    else if not @same_tracked_signature()
      @controller.page_invalidated('tracked_element_mismatch')
    else
      @merge_head()
      @render_view =>
        @replace_body()
        @new_snapshot.first_autofocusable()?.focus() unless @is_preview
        callback(@new_snapshot)

  merge_head: ->
    for element in @new_head_details.get_missing_stylesheets(@old_head_details)
      document.head.appendChild(element)
    for element in @new_head_details.get_missing_scripts(@old_head_details)
      document.head.appendChild(@create_script(element))
    for element in @old_head_details.get_provisional_elements()
      document.head.removeChild(element)
    for element in @new_head_details.get_provisional_elements()
      document.head.appendChild(element)

  replace_body: ->
    @with_pernament_elements =>
      old_body = document.body.querySelector('[data-turbolinks-body]')
      new_body = @new_body.querySelector('[data-turbolinks-body]')
      if old_body and new_body
        container = true
      else
        old_body = document.body
        new_body = @new_body
      document.adoptNode(new_body)
      for inert_script in new_body.querySelectorAll('script')
        activated_script = @create_script(inert_script)
        inert_script.replaceWith(activated_script)
      if container
        old_body.replaceWith(new_body)
      else if document.body and @new_body instanceof HTMLBodyElement
        document.body.replaceWith(@new_body)
      else
        document.documentElement.appendChild(@new_body)

  with_pernament_elements: (callback) ->
    placeholders = {}
    elements = @get_permanent_elements()
    for id, [..., new_element] of elements
      placeholder = create_placeholder(new_element)
      new_element.replaceWith(placeholder)
      placeholders[placeholder.getAttribute('content')] = placeholder
    callback()
    for id, [old_element, ...] of elements
      clone = old_element.cloneNode(true)
      old_element.replaceWith(clone)
      placeholder = placeholders[old_element.id]
      placeholder?.replaceWith(old_element)

  get_permanent_elements: ->
    elements = {}
    for old_element in @old_snapshot.get_permanent_elements(@new_snapshot)
      if new_element = @new_snapshot.get_permanent(old_element)
        elements[old_element.id] = [old_element, new_element]
    elements

  same_tracked_signature: ->
    @old_head_details.get_tracked_signature() is @new_head_details.get_tracked_signature()

create_placeholder = (permanent) ->
  element = document.createElement('meta')
  element.setAttribute('name', 'turbolinks-permanent-placeholder')
  element.setAttribute('content', permanent.id)
  element
