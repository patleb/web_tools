Object.define_singleton_methods
  from_string: ->
    'to_h'

  dup_: (object) ->
    result = {}
    for key, value of object
      result[key] = value
    result

  merge_: (target, objects...) ->
    for object in objects
      for key, value of object
        target[key] = value
    target

  deep_merge: (target, others...) ->
    for object in others
      for key, value of object
        if target[key]?.is_a?(Object) and value?.is_a?(Object)
          target[key] = Object.deep_merge({}, target[key], value)
        else
          target[key] = value
    target

  deep_sort: (object, sort_array = false) ->
    if not object?.is_a?
      result = object
    else if object.is_a Array
      result = object.map((value) -> Object.deep_sort(value, sort_array))
      result.sort() if sort_array
    else if object.is_a Object
      result = {}
      keys = object.keys_().sort (left, right) ->
        left = left.downcase()
        right = right.downcase()
        if left < right      then -1
        else if left > right then  1
        else                       0
      for key in keys
        result[key] = if not (value = object[key])?.is_a?
          value
        else if value.is_a(Array) or value.is_a Object
          Object.deep_sort(value, sort_array)
        else
          value
    else
      result = object
    result

Object.define_methods
  size_: ->
    Object.keys(this).length

  empty_: ->
    @size_() is 0

Object.define_methods
  __send__: (method, args...) ->
    if this[method]?.is_a Function
      this[method](args...)
    else
      @method_missing(method, args...)

  deconstantize_: ->
    result = Function.deconstantize_(@constructor)
    result = "#{result}::" if result
    result

  instance_exec: (block, args...) ->
    block.apply(this, args)

  instance_eval: (block) ->
    block.apply(this)

  dup_: ->
    @constructor.dup_(this)

  blank_: Object::empty_

  present_: ->
    not @blank_()

  presence_: ->
    @valueOf() unless @blank_()

  not_eql: (other) ->
    not @eql_(other)

  eql_: (other) ->
    return false unless other?.is_a Object
    return false unless @size_() is other.size_()
    for key, item of this
      if item?
        return false unless item.eql_(other[key])
      else
        return false if other[key]?
    true

  is_a: (klass) ->
    @constructor is klass

  to_a: ->
    [key, item] for key, item of this

  to_h: ->
    this

  to_json: (replacer = null, space = null) ->
    JSON.stringify(this, replacer, space)

  to_duration: ->
    new Duration(this)

  to_query: ({ blanks = true, sort = false } = {}) ->
    params = if sort then Object.deep_sort(this) else this
    params = params.map_ (param_name, param_value) ->
      switch param_value?.constructor
        when Object
          param_value.flatten_keys('][').map_ (names, value) ->
            [[param_name, '[', names, ']'].join(''), value]
        when Array
          param_value.map (value) ->
            [[param_name, '[]'].join(''), value]
        else
          [[param_name, param_value]]
    params = params.map (values) ->
      values.map ([name, value]) ->
        if name?.present_() and (blanks or value?.present_())
          "#{encodeURIComponent(name)}=#{encodeURIComponent(value)}"
    params.flatten().compact_().join('&')

  html_safe: ->
    false

  safe_text: ->
    @to_json().html_safe(true)

  tap_: (f_self) ->
    f_self(this)
    this

  has_key: (key) ->
    key of this

  delete_: (key) ->
    item = this[key]
    delete this[key]
    item

  dig_: (keys) ->
    digged = this
    keys = keys.split('.') if keys.is_a String
    keys.each_while (key) ->
      if digged.has_key?(key) or digged.has_index?(key)
        digged = digged[key]
        true
      else
        digged = undefined
        false
    digged

  each_: (f_key_item_self) ->
    for key, item of this
      f_key_item_self(key, item, this)
    return

  each_with_index: (i, f_key_item_index_self = null) ->
    [i, f_key_item_index_self] = [0, i] unless f_key_item_index_self?
    for key, item of this
      f_key_item_index_self(key, item, i++, this)
    return

  each_while: (f_key_item_self) ->
    for key, item of this
      return unless f_key_item_self(key, item, this)
    return

  each_with_object: (accumulator, f_key_item_memo_self) ->
    self = this
    @keys_().reduce (memo, key) ->
      f_key_item_memo_self(key, self[key], memo, self)
      accumulator
    , accumulator

  map_: (f_key_item_self) ->
    f_key_item_self(key, item, this) for key, item of this

  map_with_index: (i, f_key_item_index_self = null) ->
    [i, f_key_item_index_self] = [0, i] unless f_key_item_index_self?
    f_key_item_index_self(key, item, i++, this) for key, item of this

  select_: (f_key_item) ->
    result = {}
    for key, item of this when f_key_item(key, item)
      result[key] = item
    result

  select_map: (f_key_item) ->
    result = []
    for key, item of this when (value = f_key_item(key, item))
      result.push(value)
    result

  reject_: (f_key_item) ->
    result = {}
    for key, item of this when not f_key_item(key, item)
      result[key] = item
    result

  flatten_keys: (separator = '.', _prefix = null) ->
    @each_with_object {}, (key, item, memo) ->
      key = [_prefix, key].join(separator) if _prefix?
      if item?.is_a Object
        item.flatten_keys(separator, key).each_ (nested_key, nested_item) ->
          memo[nested_key] = nested_item
      else
        memo[key] = item

  find_: (f_key_item_self) ->
    for key, item of this
      return item if f_key_item_self(key, item, this)
    return

  keys_: ->
    Object.keys(this)

  values_: ->
    item for key, item of this

  values_at: (keys...) ->
    this[key] for key in keys

  slice_: (keys...) ->
    result = {}
    for key in keys
      result[key] = this[key] if key of this
    result

  except_: (keys...) ->
    result = {}
    for key, item of this
      result[key] = item if key not in keys
    result

  transform_keys: (f_key) ->
    @each_with_object {}, (key, item, memo) ->
      memo[f_key(key)] = item

  transform_values: (f_item) ->
    @each_with_object {}, (key, item, memo) ->
      memo[key] = f_item(item)

  compact_: ->
    @select_ (key, item) -> item?

  compact_blank: ->
    @select_ (key, item) -> item?.present_()

  first_: (n = 1) ->
    key = @keys_().first_(n)
    return [key, this[key]] if n is 1
    @slice_(key...)

  last_: (n = 1) ->
    key = @keys_().last_(n)
    return [key, this[key]] if n is 1
    @slice_(key...)

  merge_: (objects...) ->
    @constructor.merge_(this, objects...)

  deep_merge: (others...) ->
    @constructor.deep_merge(this, others...)
