class Turbolinks.SnapshotRenderer extends Turbolinks.Renderer
  constructor: (@old_snapshot, @new_snapshot, @is_preview) ->
    super()
    @old_head_details = @old_snapshot.head_details
    @new_head_details = @new_snapshot.head_details
    @old_body = @old_snapshot.body
    @new_body = @new_snapshot.body

  render: (callback) ->
    if @should_render()
      @merge_head()
      @render_view =>
        @replace_body()
        @new_snapshot.first_autofocusable()?.focus() unless @is_preview
        callback()
    else
      @controller.invalidate_view()

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
    placeholders =
      for permanent in @old_snapshot.get_permanent_elements(@new_snapshot)
        placeholder = create_placeholder(permanent)
        new_element = @new_snapshot.get_permanent(permanent)
        replace_with(permanent, placeholder.element)
        replace_with(new_element, permanent)
        placeholder
    for inert_script in @new_body.querySelectorAll('script')
      activated_script = @create_script(inert_script)
      replace_with(inert_script, activated_script)
    replace_with(document.body, @new_body)
    for { element, permanent } in placeholders
      clone = permanent.cloneNode(true)
      replace_with(element, clone)

  should_render: ->
    @new_snapshot.is_visitable() and @same_tracked_signature()

  same_tracked_signature: ->
    @old_head_details.get_tracked_signature() is @new_head_details.get_tracked_signature()

create_placeholder = (permanent) ->
  element = document.createElement('meta')
  element.setAttribute('name', 'turbolinks-permanent-placeholder')
  element.setAttribute('content', permanent.id)
  { element, permanent }

replace_with = (from, to) ->
  if parent = from.parentNode
    parent.replaceChild(to, from)
