class Js.StorageConcept
  alias: 'Js.Storage'

  readers: ->
    root: -> storage_node(@ROOT)
    root_permanent: -> storage_node(@ROOT_PERMANENT, true)

  constants: ->
    ROOT: '#js_storage'
    ROOT_PERMANENT: '#js_storage_permanent'
    CHANGE: 'js_storage:change'

  debug: (@__debug) ->

  get_value: (name, options = {}) ->
    @get(name, options)[name]

  get: (names...) ->
    { permanent = false, scope = '' } = names.extract_options()
    if names.length
      result = names.map (name) =>
        [name, cast_value(@storage(permanent).find("[name='#{scope}:#{name}']"))]
    else
      result = @storage(permanent).$("[name^='#{scope}:']").map (input) =>
        [input.name.sub(///^#{scope.safe_regex()}:///, ''), cast_value(input)]
    result.reject(([name, value]) -> value is undefined).to_h()

  set: (inputs, { submitter = null, permanent = false, scope = '', event = true } = {}) ->
    changed = false
    changes = inputs.each_with_object {}, (name, value, memo) =>
      if input = @storage(permanent).find("[name='#{scope}:#{name}']")
        value_was = cast_value(input)
      else
        input = input$ type: 'hidden', name: "#{scope}:#{name}", autocomplete: 'off'
        @storage(permanent).appendChild(input)
      if value_was is undefined or not value_was? and value? or value_was? and not value?.eql(value_was)
        cast = type_caster(value)
        changed = true
        changes = memo[name] = [value, value_was]
        input.setAttribute('value', if value? then value.safe_text() else null)
        input.setAttribute('data-cast', cast) if cast
        @log permanent, scope, name, value, value_was
    Rails.fire(@storage(permanent), @CHANGE, { submitter, permanent, scope, changes }) if event and changed

  storage: (permanent) ->
    if permanent then @root_permanent else @root

  # Private

  log: (permanent, scope, name, value, value_was) =>
    tag = "[STORAGE][#{if permanent then 'P' else '-'}]"
    @log_debug "#{tag}[#{scope}:#{name}] #{value_was?.safe_text()} => #{value?.safe_text()}"

  log_debug: (msg) ->
    Logger.debug(msg) if @__debug

  storage_node = (id_selector, permanent) ->
    unless (node = Rails.find(id_selector))
      body = document.body.find('[data-turbolinks-body]') ? document.body
      if permanent
        node = div$ id_selector, 'data-turbolinks-permanent': true
      else
        node = div$ id_selector
      body.appendChild(node)
    node

  cast_value = (input) ->
    if input?
      value = input.value
      value = value[cast]() if value? and cast = input.getAttribute('data-cast')
      value
    else
      undefined
