class Js.StorageConcept extends Js.Base
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
      result = @storage(permanent).$("[name^='#{scope}:']").map (element) =>
        [element.name.sub(///^#{scope.safe_regex()}:///, ''), cast_value(element)]
    result.reject(([name, value]) -> value is undefined).to_h()

  set: (inputs, { submitter = null, permanent = false, scope = '', event = true } = {}) ->
    changed = false
    changes = inputs.each_with_object {}, (name, value, memo) =>
      if element = @storage(permanent).find("[name='#{scope}:#{name}']")
        value_was = cast_value(element)
      else
        element = input$ type: 'hidden', name: "#{scope}:#{name}", autocomplete: 'off'
        @storage(permanent).appendChild(element)
      unless value?
        value = null
        cast = 'to_null'
      cast ?= switch value.constructor
        when Number
          if value.is_integer() then 'to_i' else 'to_f'
        when Boolean
          'to_b'
        when Date
          serialized_value = JSON.stringify(value).gsub('"', '')
          'to_date'
        when Array
          serialized_value = JSON.stringify(value)
          'to_a'
        when Object
          serialized_value = JSON.stringify(value)
          'to_h'
      if value_was is undefined or value isnt value_was
        changed = true
        changes = memo[name] = [value, value_was]
        element.setAttribute('value', serialized_value ? value)
        element.setAttribute('data-cast', cast) if cast
        Rails.set(element, { value_was })
        @log permanent, scope, name, value, value_was
    Rails.fire(@storage(permanent), @CHANGE, { submitter, permanent, scope, changes }) if event and changed

  storage: (permanent) ->
    if permanent then @root_permanent else @root

  # Private

  log: (permanent, scope, name, value, value_was) =>
    tag = "[STORAGE][#{if permanent then 'P' else '-'}]"
    @log_debug "#{tag}[#{scope}:#{name}] #{JSON.stringify(value_was)} => #{JSON.stringify(value)}"

  log_debug: (msg) ->
    Logger.debug(msg) if @__debug

  storage_node = (id_selector, permanent) ->
    unless (element = Rails.find(id_selector))
      body = document.body.find('[data-turbolinks-body]') ? document.body
      if permanent
        element = div$ id_selector, 'data-turbolinks-permanent': true
      else
        element = div$ id_selector
      body.appendChild(element)
    element

  cast_value = (element) ->
    if element?
      value = element.value
      value = value[cast]() if cast = element.getAttribute('data-cast')
      value
    else
      undefined
