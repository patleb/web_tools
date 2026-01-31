class Js.StorageConcept
  alias: 'Js.Storage'

  memoizers: ->
    root: -> storage_node(@ROOT)
    root_permanent: -> storage_node(@ROOT_PERMANENT, true)

  constants: ->
    ROOT: '#js_storage'
    ROOT_PERMANENT: '#js_storage_permanent'
    ROOTS: -> "#{@ROOT},#{@ROOT_PERMANENT}"
    CHANGE: 'js_storage:change'

  debug: (@__debug) ->
  pad: (@__pad) ->

  unnamed: (scope, name) ->
    return scope unless name.include(':')
    name.split(':')[0]

  unscoped: (name) ->
    return if name.ends_with(':')
    name.split(':').last()

  scoped: (name, scope) ->
    return name if name.include(':')
    "#{scope}:#{name}"

  get_changes: (name, options = {}) ->
    value = @get_value(name, options)
    value_was = @get_value(name, { was: true }.merge options)
    unless value?.is_a(Object) and value_was?.is_a(Object)
      if not eql value, value_was
        return { "#{@unscoped name}": [value, value_was] }
      else
        return {}
    changes = {}
    keys = []
    for key, item of value
      keys.push key
      item_was = value_was[key]
      changes[key] = [item, item_was] if not eql item, item_was
    for key, item_was of value_was.except(keys...)
      changes[key] = [undefined, item_was]
    changes

  get_change: (name, options = {}) ->
    value = @get_value(name, options)
    value_was = @get_value(name, { was: true }.merge options)
    [value, value_was] if not eql value, value_was

  get_value: (name, options = {}) ->
    @get(name, options)[@unscoped name]

  has_value: (name, options = {}) ->
    @get(name, options).has_key(@unscoped name)

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
    changes = inputs.each_with_object {}, (name, value, memo) =>
      scoped_name = @scoped name, scope
      if input = @storage(permanent).find("[name='#{scoped_name}']")
        value_was = input.get_value()
      else
        input = input$ type: 'hidden', name: "#{scoped_name}", autocomplete: 'off'
        @storage(permanent).appendChild(input)
      if value_was is undefined or not eql value, value_was
        cast = type_caster(value)
        changes = memo[@unscoped name] = [value, value_was]
        input.setAttribute('value', if value? then value.safe_text() else null)
        input.setAttribute('data-was', value_was.safe_text()) if was and value_was?
        if cast
          input.setAttribute('data-cast', cast)
        else
          input.removeAttribute('data-cast')
        if value?.is_a Object
          args = value.each_with_object {}, (key, value, memo) ->
            return unless cast = json_caster(value)
            memo[key] = cast
          input.setAttribute('data-args', args.safe_text()) unless args.empty()
        @log permanent, scoped_name, value, value_was
    @fire(changes, { submitter, permanent, scope }) if event
    changes

  fire: (changes, { submitter = null, permanent = false, scope = '' } = {}) ->
    @storage(permanent).fire(@CHANGE, { submitter, permanent, scope, changes }) unless changes.empty()

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

  log: (permanent, scoped_name, value, value_was) ->
    tag = "[STORAGE][#{if permanent then 'P' else '-'}][#{scoped_name}]"
    tag = tag.ljust @__pad, '-' if @__pad
    value = 'null' unless value?
    value_was = 'null' if value_was is null
    @log_debug "#{tag} now: #{value.safe_text()} \n#{tag} was: #{value_was?.safe_text()}"

  log_debug: (msg) ->
    Logger.debug(msg) if @__debug
