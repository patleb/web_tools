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
        scoped_name = if name.include(':') then name else "#{scope}:#{name}"
        [name.split(':').last(), @storage(permanent).find("[name='#{scoped_name}']")?.get_value()]
    else
      result = @storage(permanent).$("[name^='#{scope}:']").map (input) =>
        [input.name.sub(///^#{scope.safe_regex()}:///, ''), input.get_value()]
    result.reject(([name, value]) -> value is undefined).to_h()

  set: (inputs, { submitter = null, permanent = false, scope = '', event = true } = {}) ->
    changed = false
    changes = inputs.each_with_object {}, (name, value, memo) =>
      if input = @storage(permanent).find("[name='#{scope}:#{name}']")
        value_was = input.get_value()
      else
        input = input$ type: 'hidden', name: "#{scope}:#{name}", autocomplete: 'off'
        @storage(permanent).appendChild(input)
      if value_was is undefined or not eql value, value_was
        cast = type_caster(value)
        changed = true
        changes = memo[name] = [value, value_was]
        input.setAttribute('value', if value? then value.safe_text() else null)
        input.setAttribute('data-cast', cast) if cast
        @log permanent, scope, name, value, value_was
    @storage(permanent).fire(@CHANGE, { submitter, permanent, scope, changes }) if event and changed
    changes

  storage: (permanent) ->
    if permanent then @root_permanent else @root

  # Private

  storage_node = (id_selector, permanent) ->
    unless (node = Rails.find(id_selector))
      body = document.body.find('[data-turbolinks-body]') ? document.body
      if permanent
        node = div$ id_selector, 'data-turbolinks-permanent': true
      else
        node = div$ id_selector
      body.appendChild(node)
    node

  log: (permanent, scope, name, value, value_was) =>
    tag = "[STORAGE][#{if permanent then 'P' else '-'}]"
    @log_debug "#{tag}[#{scope}:#{name}] #{value_was?.safe_text()} => #{value?.safe_text()}"

  log_debug: (msg) ->
    Logger.debug(msg) if @__debug
