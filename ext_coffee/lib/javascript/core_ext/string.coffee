ISO8601_SUPPORT = Date.parse('2011-01-01T12:00:00-05:00').present()
ISO8601_PATTERN = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(Z|[-+]?[\d:]+)$/
HTML_ESCAPES =
  '&': '&amp;'
  '<': '&lt;'
  '>': '&gt;'
  '"': '&quot;'
  "'": '&#x27;'
  '`': '&#x60;'
PLURAL = [
  [/(x|ch|ss|sh)$/i, '$1es'],
  [/([^aeiouy]|qu)y$/i, '$1ies'],
  [/sis$/i, 'ses'],
  [/(alias|status)$/i, '$1es'],
  [/^(ax|test)is$/i, '$1es'],
]
SINGULAR = [
  [/(alias|status)(es)?$/i, '$1'],
  [/^(a)x[ie]s$/i, '$1xis'],
  [/(x|ch|ss|sh)es$/i, '$1'],
  [/([^aeiouy]|qu)ies$/i, '$1y'],
  [/(^analy)(sis|ses)$/i, '$1sis'],
]
ANCHOR = '::'
# NOTE: private scopes/methods are excluded
String.CONSTANTIZABLE = /^[A-Z][\w.:]*$/i
String.SCOPED_CONSTANTIZABLE = /^[A-Z]\w*((\.|::)[A-Z]\w*)+$/i

String.override_methods
  sub: String::replace

  dup: not_implemented

  to_a: ->
    result = JSON.safe_parse(this)
    throw 'invalid value for Array' unless result?.is_a Array
    result

  to_h: (casts = {}) ->
    result = JSON.safe_parse(this)
    throw 'invalid value for Object' unless result?.is_a Object
    casts.for_each (key, cast) ->
      result[key] = switch cast
        when  'nan' then  NaN
        when  'inf' then  Infinity
        when '-inf' then -Infinity
        else result[key][cast]()
    result

  blank: ->
    @trim().length is 0

  empty: ->
    @length is 0

  eql: (other) ->
    return false unless other?.is_a String
    @valueOf() is other.valueOf()

  first: (n = 1) ->
    return this[0] if n is 1
    this[0...n]

  last: (n = 1) ->
    return this[@length - 1] if n is 1
    this[-n..-1]

  html_safe: (safe = null) ->
    if safe?
      value = if primitive(this) then new @constructor(this) else this
      value._html_safe = !!safe
      value
    else
      !!@_html_safe

  safe_text: (force = false) ->
    return this if not force and @html_safe()
    return @html_safe(true) unless this and /[&<>"'`]/.test(this)
    @replace(/[&<>"'`]/g, (char) -> HTML_ESCAPES[char]).html_safe(true)

String.define_readers
  begin: -> 0
  end:   -> if @length then @length - 1 else 0

String.define_methods
  add: (other) ->
    value = this + other
    value = value.html_safe(true) if @html_safe() and other.html_safe()
    value

  safe_regex: ->
    return this unless this and /[\\^$.*+?()[\]{}|]/.test(this)
    @replace(/[\\^$.*+?()[\]{}|]/g, '\\$&')

  html_blank: ->
    @gsub(/(<\/?p>|&nbsp;|<br>)/, '').blank()

  to_null: ->
    return null if @blank() or @match(/^(null|undefined)$/)
    throw 'invalid value for null'

  to_b: ->
    return true if @match(/^(true|t|yes|y|1|1\.0|✓)$/i)
    return false if @blank() or @match(/^(false|f|no|n|0|0\.0|✘)$/i)
    throw 'invalid value for Boolean'

  to_i: (base = null) ->
    value = if @toLowerCase().starts_with('0x') then this else @replace(/^0+/, '')
    return 0 if @length > 0 and value is ''
    parseInt(value, base)

  to_f: (type = null) ->
    value = this
    switch type
      when 'percent'
        return parseFloat(value) / 100
      when 'metric'
        if (i = Number.METRIC_PREFIX.index value.last())?
          value = value.chop().rstrip()
          value = "#{value}e#{Number.METRIC_EXPONENT[i]}"
    parseFloat(value)

  to_s: ->
    this

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

  downcase: String::toLowerCase

  upcase: String::toUpperCase

  gsub: (pattern, string_or_f_match) ->
    pattern =
      if pattern.is_a String
        ///#{pattern.safe_regex()}///g
      else
        { source, flags, global } = pattern
        flags += 'g' unless global
        new RegExp(source, flags)
    @replace(pattern, string_or_f_match)

  gsub_keys: (values, { anchor = ANCHOR } = {}) ->
    string = @valueOf()
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

  gsub_template: (values) ->
    string = @valueOf()
    for name, value of values
      string = string.replace(///\{\{\s*#{name.safe_regex()}\s*}}///g, value.toString())
    string

  strip: String::trim

  lstrip: String::trimStart

  rstrip: String::trimEnd

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
    @charAt(0).upcase() + this[1..]

  camelize: (namespace = '.') ->
    @split(/[-_\s]+/).map((word) -> word.upcase_first()).join('')
      .split(/\/+/).map((word) -> word.upcase_first()).join(namespace)

  underscore: (namespace = '.') ->
    @gsub(namespace, '/')
      .gsub(/([A-Z\d]+)([A-Z][a-z])/, '$1_$2')
      .gsub(/([a-z\d])([A-Z])/, '$1_$2')
      .gsub('-', '_')
      .downcase()

  full_underscore: (namespace = '.') ->
    @underscore(namespace).gsub(/[\.\/]/, '_').replace(/^_/, '').replace(/_$/, '')

  parameterize: ->
    @gsub(/[^a-z0-9\-_]+/i, '-')
      .gsub(/-{2,}/, '-')
      .gsub(/^-|-$/i, '')
      .downcase()

  titleize: ->
    @humanize().gsub(/ ([^ ])/, (match) -> match.upcase())

  humanize: ->
    string = @full_underscore().gsub('_', ' ')
    string.charAt(0).upcase() + string[1..]

  pluralize: ->
    if (rule = PLURAL.find (rule) => @match rule[0])
      @sub(rule...)
    else
      "#{this}s"

  singularize: ->
    if (rule = SINGULAR.find (rule) => @match rule[0])
      @sub(rule...)
    else
      @sub(/s$/, '')

  acronym: ->
    @camelize().match(/[A-Z]/g)?.join('')

  scoped_constantizable: ->
    @match String.SCOPED_CONSTANTIZABLE

  constantizable: ->
    @match String.CONSTANTIZABLE

  constantize: ->
    if @match /[^:\w.]+/
      throw 'not a valid module or class name'
    else
      if (@constructor.constantize ?= {}).has_key @valueOf()
        return @constructor.constantize[@valueOf()]
      object = window
      scope = 'window'
      scope_was = null
      @replace(/^(\.|::)/, '').split('.').each (class_scope) ->
        return unless class_scope.match String.CONSTANTIZABLE
        class_scope.split('::').each (prototype_scope, i) ->
          scope_was = scope
          scope = prototype_scope
          parent = object
          if i is 0
            object = object[prototype_scope]
          else
            object = object::[prototype_scope]
          unless primitive(object) or object.__name__
            object.__name__ = scope
            object.__scope__ = if i is 0 then "#{scope_was}." else "#{scope_was}::"
            object.__parent__ = parent
      @constructor.constantize[@valueOf()] = object

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

  starts_with: String::startsWith

  start_with: (prefixes...) ->
    prefixes.any (prefix) =>
      @startsWith(prefix)

  ends_with: String::endsWith

  end_with: (suffixes...) ->
    suffixes.any (suffix) =>
      @endsWith(suffix)

  simple_format: ->
    formatted = @gsub /\r?\n/g, '<br>'
    formatted = formatted.html_safe(true) if @html_safe()
    formatted
