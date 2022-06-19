class Js.StorageConcept
  global: 'Js.Storage'

  getters: ->
    storage: ->
      unless (element = Rails.$0(@ROOT))
        body = document.body.$0('[data-turbolinks-body]') ? document.body
        element = div$ @ROOT
        body.appendChild(element)
      element

  constants: ->
    ROOT: '#js_storage'
    CHANGE: 'js:storage'

  get: (names...) ->
    { scope = '' } = names.extract_options()
    if names.length
      result = names.map (name) =>
        @cast_value @storage().$0("[name='#{scope}:#{name}']")
    else
      result = @storage().$("[name^='#{scope}:']").map (element) =>
        @cast_value element
    result = result[0] unless names.length > 1
    result

  set: (inputs, { scope = '' } = {}) ->
    changed = false
    inputs.each (name, value) =>
      if element = @storage().$0("[name='#{scope}:#{name}']")
        value_was = @cast_value(element)
      else
        element = input$ type: 'hidden', name: "#{scope}:#{name}"
        @storage().appendChild(element)
      unless value?
        value = null
        cast = 'to_null'
      cast ?= switch value.constructor
        when Number
          if value.is_integer() then 'to_i' else 'to_f'
        when Boolean
          'to_b'
        when Date
          json_value = JSON.stringify(value).gsub('"', '')
          'to_date'
        when Array
          json_value = JSON.stringify(value)
          'to_a'
        when Object
          json_value = JSON.stringify(value)
          'to_h'
      Rails.set(element, { value_was })
      element.setAttribute('value', json_value ? value)
      element.setAttribute('data-cast', cast) if cast
      if value_was is undefined or value isnt value_was
        changed = true
        Rails.fire(element, "#{@CHANGE}:#{scope}:#{name}", { value, value_was })
    if scope and changed
      Rails.fire(@storage(), "#{@CHANGE}:#{scope}")

  # Private

  cast_value: (element) ->
    if element?
      value = element.value
      value = value[cast]() if cast = element.getAttribute('data-cast')
      value
    else
      undefined
