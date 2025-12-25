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

  unnamed: (scope, name) ->
    return scope unless name.include(':')
    name.split(':')[0]

  unscoped: (name) ->
    name.split(':').last()

  scoped: (name, scope) ->
    return name if name.include(':')
    "#{scope}:#{name}"

  get_value: (name, options = {}) ->
    @get(name, options)[@unscoped name]

  get: (names...) ->
    { permanent = false, scope = '', was = false } = names.extract_options()
    was = { was }
    if names.length
      result = names.map (name) =>
        scoped_name = @scoped name, scope
        [@unscoped(name), @storage(permanent).find("[name='#{scoped_name}']")?.get_value(was)]
    else
      result = @storage(permanent).$("[name^='#{scope}:']").map (input) =>
        [input.name.sub(///^#{scope.safe_regex()}:///, ''), input.get_value(was)]
    result.reject(([name, value]) -> value is undefined).to_h()

  set: (inputs, { submitter = null, permanent = false, scope = '', event = true, was = false } = {}) ->
    changed = false
    changes = inputs.each_with_object {}, (name, value, memo) =>
      scoped_name = @scoped name, scope
      if input = @storage(permanent).find("[name='#{scoped_name}']")
        value_was = input.get_value()
      else
        input = input$ type: 'hidden', name: "#{scoped_name}", autocomplete: 'off'
        @storage(permanent).appendChild(input)
      if value_was is undefined or not eql value, value_was
        cast = type_caster(value)
        changed = true
        changes = memo[@unscoped name] = [value, value_was]
        input.setAttribute('value', if value? then value.safe_text() else null)
        input.setAttribute('data-was', value_was.safe_text()) if was and value_was?
        input.setAttribute('data-cast', cast) if cast
        @log permanent, scoped_name, value, value_was
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

  log: (permanent, scoped_name, value, value_was) =>
    tag = "[STORAGE][#{if permanent then 'P' else '-'}]"
    @log_debug "#{tag}[#{scoped_name}] #{value_was?.safe_text()} => #{value?.safe_text()}"

  log_debug: (msg) ->
    Logger.debug(msg) if @__debug
