Object.define_methods
  is_a: (klass) ->
    this.constructor == klass

  to_a: ->
    this.each_with_object [], (key, value, memo) ->
      memo.push [key, value]

  to_h: ->
    this

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

  has_key: (key) ->
    _.hasIn(this, key)

  delete: (key) ->
    value = this[key]
    delete this[key]
    value

  dig: (keys) ->
    digged = this
    keys.split('.').each_while (key) ->
      if digged.has_key(key)
        digged = digged[key]
        true
      else
        digged = undefined
        false
    digged

  any: (f_key_item_self) ->
    if f_key_item_self?
      f = (item, key, self) ->
        f_key_item_self(key, item, self)
      _.some this, f
    else
      this.keys().length > 0

  all: (f_key_item_self) ->
    f = (item, key, self) ->
      f_key_item_self(key, item, self)
    _.every this, f

  each: (f_key_item_self) ->
    f = (item, key, self) ->
      f_key_item_self(key, item, self)
      true
    _.forOwn this, f

  each_while: (f_key_item_self) ->
    f = (item, key, self) ->
      f_key_item_self(key, item, self)
    _.forOwn this, f

  each_with_object: (accumulator, f_key_item_memo_self) ->
    f = (memo, item, key, self) ->
      f_key_item_memo_self(key, item, memo, self)
      accumulator
    _.reduce(this, f, accumulator)

  map: (f_key_item_self) ->
    f = (item, key, self) ->
      f_key_item_self(key, item, self)
    _.map this, f

  flatten_keys: (separator = '-', prefix = null) ->
    this.each_with_object {}, (key, item, memo) ->
      key = [prefix, key].join(separator) if prefix?
      if item?.is_a(Object)
        item.flatten_keys(separator, key).each (nested_key, nested_item) ->
          memo[nested_key] = nested_item
      else
        memo[key] = item

  find: (f_key_item_self) ->
    f = (item, key, self) ->
      f_key_item_self(key, item, self)
    _.find(this, f)

  keys: ->
    _.keys this

  vals: ->
    _.values this

  vals_at: (keys...) ->
    _.at(this, keys.unsplat())

  select: (f_key_item) ->
    f = (item, key) ->
      f_key_item(key, item)
    _.pickBy(this, f)

  reject: (f_key_item) ->
    f = (item, key) ->
      f_key_item(key, item)
    _.omitBy(this, f)

  slice: (keys...) ->
    _.pick(this, keys.unsplat())

  except: (keys...) ->
    _.omit(this, keys.unsplat())

  compact: ->
    this.select (key, item) -> item?

  merge: (other_hashes..., f_val_otherval_key_self_other = {}) ->
    args = other_hashes.unsplat().concat(f_val_otherval_key_self_other)
    if f_val_otherval_key_self_other.is_a(Function)
      _.assignWith {}, this, args...
    else
      _.assign {}, this, args...

  deep_merge: (other_hashes..., f_val_otherval_key_self_other = {}) ->
    args = other_hashes.unsplat().concat(f_val_otherval_key_self_other)
    if f_val_otherval_key_self_other.is_a(Function)
      _.mergeWith {}, this, args...
    else
      _.merge {}, this, args...

  dup: ->
    _.clone(this)

  deep_dup: ->
    _.cloneDeep(this)

  super_2: (name, args...) ->
    @constructor.__super__.__proto__[name].apply(this, args)

  super_3: (name, args...) ->
    @constructor.__super__.__proto__.__proto__[name].apply(this, args)
