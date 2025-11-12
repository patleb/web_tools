Array.define_singleton_methods
  wrap: (object) ->
    if object?
      if Array.is_array(object)
        Array::slice.call(object)
      else
        [object]
    else
      []

  is_array: (object) ->
    if not object?
      false
    else if typeof window.Symbol is 'function'
      typeof object[Symbol.iterator] is 'function' and
      typeof object.length is 'number' and
      typeof object isnt 'string'
    else if Array.isArray(object) \
    or object instanceof HTMLCollection \
    or object instanceof NodeList \
    or object instanceof DOMTokenList \
    or Object.prototype.toString.call(object) is '[object Arguments]'
      true
    else if typeof object isnt 'object' or not object.hasOwnProperty('length') or object.length < 0
      false
    else
      object.length is 0 or !!(object[0]?.nodeType)

Array.polyfill_methods
  find: (f_item_index_self) ->
    for item, i in this
      return item if f_item_index_self(item, i, this)
    return

Array.decorate_methods
  map: (f_item_index_self, arg) ->
    if f_item_index_self.is_a String
      @super (item) -> item[f_item_index_self](arg)
    else
      @super(f_item_index_self, arg)

Array.override_methods
  dup: ->
    @slice()

  to_a: ->
    this

  to_h: ->
    @each_with_object {}, ([key, value...], memo) ->
      throw 'Array#to_h: invalid conversion structure' if value.length isnt 1
      memo[key] = value[0]

  size: ->
    @length

  eql: (other) ->
    return false unless other?.is_a Array
    return false unless @length is other.length
    for item, i in this
      if item?
        return false unless item.eql(other[i])
      else
        return false if other[i]?
    true

  any: (f_item_index_self) ->
    if f_item_index_self?
      @some(f_item_index_self)
    else
      @length > 0

  all: (f_item_index_self) ->
    @every(f_item_index_self)

  none: (f_item_index_self) ->
    @every (item, index, self) ->
      not f_item_index_self(item, index, self)

  each: (f_item_index_self) ->
    @forEach(f_item_index_self)
    return

  each_while: (f_item_index_self) ->
    for item, i in this
      return unless f_item_index_self(item, i, this)
    return

  each_with_object: (accumulator, f_item_memo_index_self) ->
    @reduce (memo, item, index, self) ->
      f_item_memo_index_self(item, memo, index, self)
      accumulator
    , accumulator

  select: (f_item_index_self) ->
    @filter(f_item_index_self)

  select_map: (f_item_index_self) ->
    value for item, i in this when (value = f_item_index_self(item, i, this))

  reject: (f_item_index_self) ->
    @filter (item, index, self) ->
      not f_item_index_self(item, index, self)

  except: (items...) ->
    item for item in this when item not in items

  compact: ->
    @filter (item) -> item?

  compact_blank: ->
    @filter (item) -> item?.present()

  first: ->
    this[0]

  merge: (others...) ->
    for other in others
      @push(other...)
    this

Array.define_methods
  to_s: ->
    @toString()

  to_set: ->
    @map((v) -> [v, true]).to_h()

  has_index: (index) ->
    0 <= index < @length

  clear: (force = false) ->
    if force
      @splice(0)
    else
      @length = 0

  index: (item, start_index = 0) ->
    if (index = @indexOf(item, start_index)) isnt -1
      index

  include: (item) ->
    item in this

  exclude: (item) ->
    not @include(item)

  max: ->
    Math.max this

  min: ->
    Math.min this

  each_slice: (size = 1) ->
    return [] unless size? and size >= 1
    result = []
    i = 0
    result.push(@slice(i, i += size)) while i < @length
    result

  pluck: (keys...) ->
    if keys.length is 1
      key = keys[0]
      @map (item) -> item[key]
    else
      @map (item) -> item.values_at(keys...)

  sort_by: (f_item_index_self) ->
    @map (item, index, self) ->
      { item, index, weight: f_item_index_self(item, index, self) }
    .sort (left, right) ->
      lw = left.weight; rw = right.weight
      if lw isnt rw
        return 1 if not lw? or lw > rw
        return -1 if not rw? or lw < rw
      left.index - right.index
    .pluck('item')

  last: (n = 1) ->
    return this[@length - 1] if n is 1
    this[-n..-1]

  find_index: (f_item_index_self) ->
    for i in [0...@length]
      return i if f_item_index_self(this[i], i, this)
    return

  flatten: ->
    @reduce (memo, item) ->
      memo.concat(if item?.is_a(Array) then item.flatten() else item)
    , []

  add: (others...) ->
    @concat others...

  sum: (f_item_index_self = (v) -> v) ->
    value = 0
    for i in [0...@length]
      value += f_item_index_self(this[i], i, this)
    value

  intersection: (other) ->
    value for value in this when value in other

  union: (others...) ->
    result = {}
    for array in [this, others...]
      result[array[i]] = array[i] for i in [0...array.length]
    value for key, value of result

  zip: (others...) ->
    arrays = [this, others...]
    length = Math.min((array.length for array in arrays)...)
    for i in [0...length]
      array[i] for array in arrays

  uniq: ->
    result = {}
    result[this[i]] = this[i] for i in [0...@length]
    value for key, value of result

  extract_options: ->
    if @last()?.is_a Object
      @pop()
    else
      {}
