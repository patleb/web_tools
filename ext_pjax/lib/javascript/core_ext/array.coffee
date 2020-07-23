Array.define_methods
  is_a: (klass) ->
    this.constructor == klass

  to_a: ->
    this

  to_h: ->
    this.each_with_object {}, ([key, value], memo) ->
      memo[key] = value

  to_s: ->
    this.toString()

  blank: ->
    _.isEmpty(this)

  present: ->
    !this.blank()

  presence: ->
    this.valueOf() unless this.blank()

  empty: ->
    _.isEmpty(this)

  eql: (other) ->
    _.isEqual(this, other)

  clear: ->
    this.length = 0

  index: (object, start_index = 0) ->
    if (index = this.indexOf(object, start_index)) != -1
      index

  any: (f_item_index_self_or_keys) ->
    if f_item_index_self_or_keys?
      _.some(this, f_item_index_self_or_keys)
    else
      this.length > 0

  all: (f_item_index_self_or_keys) ->
    _.every(this, f_item_index_self_or_keys)

  includes: (object, start_index = 0) ->
    _.includes(this, object, start_index)

  excludes: (object, start_index = 0) ->
    !this.includes(object, start_index)

  each: (f_item_index_self) ->
    f = (item, index, self) ->
      f_item_index_self(item, index, self)
      true
    _.forEach this, f

  each_while: (f_item_index_self) ->
    _.forEach this, f_item_index_self

  each_with_object: (accumulator, f_item_memo_index_self) ->
    f = (memo, item, index, self) ->
      f_item_memo_index_self(item, memo, index, self)
      accumulator
    _.reduce(this, f, accumulator)

  each_slice: (size = 1) ->
    _.chunk(this, size)

  sort_by: (f_item_or_keys...) ->
    _.sortBy(this, f_item_or_keys.unsplat())

  select: (f_item_index_self_or_keys) ->
    _.filter(this, f_item_index_self_or_keys)

  reject: (f_item_index_self_or_keys) ->
    _.reject(this, f_item_index_self_or_keys)

  except: (objects...) ->
    _.without(this, objects.unsplat()...)

  compact: ->
    this.select (item) -> item?

  delete: (objects...) ->
    _.pull(this, objects.unsplat()...)

  delete_if: (f_item) ->
    _.remove(this, f_item)

  dup: ->
    _.clone(this)

  deep_dup: ->
    _.cloneDeep(this)

  drop: (n = 1) ->
    _.drop(this, n)

  first: (n = 1) ->
    return this[0] if n == 1
    _.take(this, n)

  last: (n = 1) ->
    return this[this.length - 1] if n == 1
    _.takeRight(this, n)

  flatten: ->
    _.flattenDeep(this)

  add: (other_arrays...) ->
    _.concat this, other_arrays...

  union: (other_arrays...) ->
    _.union this, other_arrays...

  zip: (other_arrays...) ->
    _.zip(this, other_arrays...)

  uniq: ->
    _.uniq(this)

  unsplat: ->
    if this.length == 1 && this[0]?.is_a(Array)
      this[0]
    else
      this

  extract_options: ->
    if this.last()?.is_a(Object)
      this.pop()
    else
      {}

Array.decorate_methods
  find: (f_item_index_self_or_keys) ->
    if arguments.length == 1
      _.find(this, f_item_index_self_or_keys)
    else
      this.super.apply(this, arguments)
