ISO8601_SUPPORT = Date.parse('2011-01-01T12:00:00-05:00').present()
ISO8601_PATTERN = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(Z|[-+]?[\d:]+)$/
HTML_ESCAPES =
  '&': '&amp;'
  '<': '&lt;'
  '>': '&gt;'
  '"': '&quot;'
  "'": '&#x27;'
  '`': '&#x60;'

String.override_methods
  sub: (pattern, string_or_f_match) ->
    @replace(pattern, string_or_f_match)

  dup: not_implemented

  to_a: ->
    result = JSON.safe_parse(this)
    throw 'invalid value for Array' unless result.is_a Array
    result

  to_h: ->
    result = JSON.safe_parse(this)
    throw 'invalid value for Object' unless result.is_a Object
    result

  blank: ->
    @trim().length is 0

  size: ->
    @length

  eql: (other) ->
    @valueOf() is other

  first: ->
    this[0]

String.define_methods
  to_null: ->
    return null if @blank() or @match(/^(null|undefined)$/)
    throw 'invalid value for null'

  to_b: ->
    return true if @match(/^(true|t|yes|y|1|1\.0|✓)$/i)
    return false if @blank() or @match(/^(false|f|no|n|0|0\.0|✘)$/i)
    throw 'invalid value for Boolean'

  to_i: (base = null) ->
    value = if @toLowerCase().startsWith('0x') then this else @replace(/^0+/, '')
    return 0 if @length > 0 and value is ''
    parseInt(value, base)

  to_f: ->
    parseFloat(this)

  to_d: ->
    parseFloat(this)

  to_s: ->
    @toString()

  to_date: ->
    return Date.current() if @valueOf() is 'now'
    if not ISO8601_SUPPORT and (matches = @match(ISO8601_PATTERN))
      [_, year, month, day, hour, minute, second, zone] = matches
      offset = zone.replace(':', '') if zone isnt 'Z'
      date = "#{year}/#{month}/#{day} #{hour}:#{minute}:#{second} GMT#{[offset]}"
    else
      date = this
    new Date(Date.parse(date))

  to_html: ->
    Array.wrap(new DOMParser().parseFromString(this, 'text/html').body.children)

  last: (n = 1) ->
    return this[@length - 1] if n is 1
    this[-n..-1]

  chars: ->
    @split('')

  index: (pattern, start_index = 0) ->
    if pattern.is_a RegExp
      if (index = @search(pattern)) isnt -1
        index
    else if (index = @indexOf(pattern, start_index)) isnt -1
      index

  rindex: (string, start_index = +Infinity) ->
    if (index = @lastIndexOf(string, start_index)) isnt -1
      index

  include: (string, start_index = 0) ->
    @indexOf(string, start_index) isnt -1

  exclude: (string, start_index = 0) ->
    not @include(string, start_index)

  safe_text: ->
    return this unless this and /[&<>"'`]/.test(this)
    @replace(/[&<>"'`]/g, (char) -> HTML_ESCAPES[char])

  safe_regex: ->
    return this unless this and /[\\^$.*+?()[\]{}|]/.test(this)
    @replace(/[\\^$.*+?()[\]{}|]/g, '\\$&')

  downcase: ->
    @toLowerCase()

  upcase: ->
    @toUpperCase()

  gsub: (pattern, string_or_f_match) ->
    pattern =
      if pattern.is_a String
        ///#{pattern.safe_regex()}///g
      else
        { source, flags, global } = pattern
        flags += 'g' unless global
        new RegExp(source, flags)
    @replace(pattern, string_or_f_match)

  gsub_keys: (string, values, { anchor = ':' } = {}) ->
    is_function = values.is_a Function
    if is_function or values.any()
      [part, parts...] = string.split(anchor)
      parts = parts.map (segment) ->
        if (name = segment.match /^\w+/)
          name = name[0]
          value = if is_function then values(name) else values[name]
          segment.sub /^\w+/, value
        else
          segment
      string = [part].add(parts).join('')
    string

  strip: ->
    @trim()

  lstrip: ->
    @trimStart()

  rstrip: ->
    @trimEnd()

  chop: ->
    this[0..-2]

  lchop: ->
    this[1..-1]

  ljust: (length = 0, chars = ' ') ->
    pad = Array(length + 1).join(chars)
    @constructor(this + pad).substring(0, length)

  rjust: (length = 0, chars = ' ') ->
    pad = Array(length + 1).join(chars)
    @constructor(pad + this).slice(-length)

  upcase_first: ->
    @charAt(0).toUpperCase() + @slice(1)

  camelize: ->
    @split(/[-_\s]+/).map((word) -> word.upcase_first()).join('')
      .split(/\/+/).map((word) -> word.upcase_first()).join('::')

  underscore: ->
    @gsub(/::/, '/')
      .gsub(/([A-Z\d]+)([A-Z][a-z])/, '$1_$2')
      .gsub(/([a-z\d])([A-Z])/, '$1_$2')
      .gsub('-', '_')
      .downcase()

  full_underscore: ->
    @underscore().gsub(/[\.\/]/, '_').replace(/^_/, '').replace(/_$/, '')

  parameterize: ->
    @gsub(/[^a-z0-9\-_]+/i, '-')
      .gsub(/-{2,}/, '-')
      .gsub(/^-|-$/i, '')
      .downcase()

  humanize: ->
    @charAt(0).toUpperCase() + @gsub('_', ' ')[1..]

  pluralize: ->
    if @end_with 'y'
      @sub(/y$/, 'ies')
    else
      "#{this}s"

  singularize: ->
    if @end_with 'ies'
      @sub(/ies$/, 'y')
    else
      @sub(/s$/, '')

  acronym: ->
    @camelize().match(/[A-Z]/g)?.join('')

  constantize: ->
    if @match /[^:\w.]+/
      throw 'not a valid module or class name'
    else
      if (@constructor.constantize ?= {}).has_key this
        return @constructor.constantize[this]
      object = window
      @replace(/^::/, '').split('.').each (class_scope) ->
        class_scope.split('::').each (prototype_scope, i) ->
          if i is 0
            object = object[prototype_scope]
          else
            object = object::[prototype_scope]
      @constructor.constantize[this] = object

  partition: (separator) ->
    if (index = @index(separator))?
      [left_start, left_end] = if index then [0, (index - 1)] else [@length, 0]
      if separator.is_a RegExp
        separator = @match(separator)[0]
      [this[left_start..left_end], separator, this[(index + separator.length)..]]
    else
      [this[0..], '', '']

  insert: (start, string, { replace = 0 } = {}) ->
    start = 0 if start < 0
    start = @length if start > @length
    rest = @length - start
    replace = 0 if replace < 0
    replace = rest if replace > rest
    "#{this[0...start]}#{string}#{this[(start + replace)..-1]}"

  start_with: (prefixes...) ->
    prefixes.any (prefix) =>
      @match ///^#{prefix.safe_regex()}///

  end_with: (suffixes...) ->
    suffixes.any (suffix) =>
      @match ///#{suffix.safe_regex()}$///

  simple_format: ->
    @gsub /\r?\n/g, '<br>'

  html_blank: ->
    @gsub(/(<\/?p>|&nbsp;|<br>)/, '').blank()

  html_safe: (safe = null) ->
    if safe?
      value = new @constructor this
      value._html_safe = !!safe
      value
    else
      !!@_html_safe
