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
    name.split(':').last_()

  scoped: (name, scope) ->
    return name if name.include(':')
    "#{scope}:#{name}"

  get_changes: (name, options = {}) ->
    value = @get_value(name, options)
    value_was = @get_value(name, { was: true }.merge_ options)
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
    for key, item_was of value_was.except_(keys...)
      changes[key] = [undefined, item_was]
    changes

  get_change: (name, options = {}) ->
    value = @get_value(name, options)
    value_was = @get_value(name, { was: true }.merge_ options)
    [value, value_was] if not eql value, value_was

  get_names: ({ permanent = false, scope = '' } = {}) ->
    @storage(permanent).$("[name^='#{scope}:']").map (input) =>
      input.name.sub(///^#{scope.safe_regex()}:///, '')

  get_value: (name, options = {}) ->
    @get(name, options)[@unscoped name]

  has_value: (name, options = {}) ->
    @get(name, options).has_key(@unscoped name)

  get: (names...) ->
    { permanent = false, scope = '', was = false } = names.extract_options()
    if names.length
      result = names.map (name) =>
        scoped_name = @scoped name, scope
        [@unscoped(name), @storage(permanent).find("[name='#{scoped_name}']")?.get_value({ was })]
    else
      result = @storage(permanent).$("[name^='#{scope}:']").map (input) =>
        [input.name.sub(///^#{scope.safe_regex()}:///, ''), input.get_value({ was })]
    result.reject_(([name, value]) -> value is undefined).to_h()

  set: (inputs, { submitter = null, permanent = false, scope = '', event = true, was = false, sync = false } = {}) ->
    changes = inputs.each_with_object {}, (name, value, memo) =>
      scoped_name = @scoped name, scope
      if input = @storage(permanent).find("[name='#{scoped_name}']")
        value_was = input.get_value()
      else
        input = input$ type: 'hidden', name: "#{scoped_name}", autocomplete: 'off'
        @storage(permanent).appendChild(input)
      if value_was is undefined or not eql value, value_was
        memo[@unscoped name] = [value, value_was]
        set_value(input, value)
        set_value(input, value_was, WAS) if was
        @log permanent, scoped_name, value, value_was
    @fire(changes, { submitter, permanent, scope }) if event
    if submitter and sync
      changes.each_ (name, [value, _]) -> submitter[name] = value
    changes

  delete: (names...) ->
    { permanent = false, scope = '' } = names.extract_options()
    if names.length
      names.each_ (name) =>
        scoped_name = @scoped name, scope
        @storage(permanent).find("[name='#{scoped_name}']")?.remove()
    else
      @storage(permanent).$("[name^='#{scope}:']").each_ (input) ->
        input.remove()

  clear: ({ permanent = false } = {}) ->
    @storage(permanent).$('input').each_ (input) ->
      input.remove()

  fire: (changes, { submitter = null, permanent = false, scope = '' } = {}) ->
    @storage(permanent).fire(@CHANGE, { submitter, permanent, scope, changes }) unless changes.empty_()

  # Private

  storage: (permanent) ->
    if permanent then @root_permanent else @root

  log: (permanent, scoped_name, value, value_was) ->
    tag = "[STORAGE][#{if permanent then 'P' else '-'}][#{scoped_name}]"
    tag = tag.ljust @__pad, '-' if @__pad
    value = 'null' unless value?
    value_was = 'null' if value_was is null
    @log_debug "#{tag} now: #{value.safe_text()} \n#{tag} was: #{value_was?.safe_text()}"

  log_debug: (msg) ->
    Logger.debug(msg) if @__debug

  set_value = (input, value, was = false) ->
    if not was
      input.set_attr('value', if value? then value.safe_text() else null)
    else if value?
      input.set_attr('data-value', value.safe_text(), WAS)
    else
      remove_was = true
      input.remove_attr('data-value', WAS)
    if not remove_was and (cast = type_caster(value))
      input.set_attr('data-cast', cast, was)
    else
      input.remove_attr('data-cast', was)
    if value?.is_a Object
      args = value.each_with_object {}, (key, value, memo) ->
        return unless cast = json_caster(value)
        memo[key] = cast
      if args.present_()
        input.set_attr('data-args', args.safe_text(), was)
      else
        input.remove_attr('data-args', was)
    else
      input.remove_attr('data-args', was)

  storage_node = (id_selector, permanent) ->
    unless (node = Rails.find(id_selector))
      body = document.body.find('[data-turbolinks-body]') ? document.body
      if permanent
        node = div$ id_selector, 'data-turbolinks-permanent': true
      else
        node = div$ id_selector
      body.appendChild(node)
    node
