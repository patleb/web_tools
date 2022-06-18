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

  is_a: (klass) ->
    @constructor is klass

  to_a: ->
    result = JSON.safe_parse(this)
    throw "invalid value for Array: '#{this}'" unless result.is_a Array
    result

  to_h: ->
    result = JSON.safe_parse(this)
    throw "invalid value for Object: '#{this}'" unless result.is_a Object
    result

  blank: ->
    @trim().length is 0

  present: ->
    not @blank()

  presence: ->
    @toString() unless @blank()

  empty: ->
    @length is 0

  eql: (other) ->
    this is other

  first: ->
    this[0]

String.define_methods
  to_b: ->
    return true if @match(/^(true|t|yes|y|1|1\.0|✓)$/i)
    return false if @blank() or @match(/^(false|f|no|n|0|0\.0|✘)$/i)
    throw "invalid value for Boolean: '#{this}'"

  to_i: (base = null) ->
    value = if @toLowerCase().startsWith('0x') then this else @replace(/^0+/, '')
    return 0 if @length > 0 && value is ''
    parseInt(value, base)

  to_f: ->
    parseFloat(this)

  to_d: ->
    parseFloat(this)

  to_s: ->
    @toString()

  to_date: ->
    Date.parse(this)

  html_blank: ->
    @gsub(/(<\/?p>|&nbsp;|<br>)/, '').blank()

  last: ->
    this[@length - 1]

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

  strip: ->
    @trim()

  lstrip: ->
    @trimStart()

  rstrip: ->
    @trimEnd()

  chop: ->
    this[0..-2]

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

  acronym: ->
    @camelize().match(/[A-Z]/g)?.join('')

  constantize: ->
    if @match /[^:\w.]+/
      throw "#{@safe_text()} isn't a valid module or class name"
    else
      object = window
      @replace(/^::/, '').split('.').each (class_scope) ->
        class_scope.split('::').each (prototype_scope, i) ->
          if i is 0
            object = object[prototype_scope]
          else
            object = object::[prototype_scope]
      object

  partition: (separator) ->
    if (index = @index(separator))?
      [left_start, left_end] = if index then [0, (index - 1)] else [@length, 0]
      if separator.is_a RegExp
        separator = @match(separator)[0]
      [this[left_start..left_end], separator, this[(index + separator.length)..]]
    else
      [this[0..], '', '']

  start_with: (prefixes...) ->
    prefixes.any (prefix) =>
      @match ///^#{prefix.safe_regex()}///

  end_with: (suffixes...) ->
    suffixes.any (suffix) =>
      @match ///#{suffix.safe_regex()}$///

  simple_format: ->
    @gsub /\r?\n/g, '<br>'

  html_safe: (safe = null) ->
    if safe?
      value = new @constructor this
      value._html_safe = !!safe
      value
    else
      !!@_html_safe
