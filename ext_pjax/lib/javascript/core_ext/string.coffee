String.define_methods
  is_a: (klass) ->
    this.constructor == klass

  to_b: ->
    return true if this.match(/^(true|t|yes|y|1|✓)$/i)
    return false if this.blank() || this.match(/^(false|f|no|n|0|✘)$/i)
    throw "invalid value for Boolean: '#{this}'"

  to_i: ->
    _.parseInt(this)

  to_f: ->
    _.toNumber(this)

  to_d: ->
    _.toNumber(this)

  to_s: ->
    this.toString()

  to_a: ->
    result = JSON.safe_parse(this)
    throw "invalid value for Array: '#{this}'" unless result.is_a(Array)
    result

  to_h: ->
    result = JSON.safe_parse(this)
    throw "invalid value for Object: '#{this}'" unless result.is_a(Object)
    result

  to_timestamp: ->
    Date.parse(this)

  blank: ->
    _.isEmpty(_.trim(this))

  present: ->
    !this.blank()

  presence: ->
    this.toString() unless this.blank()

  empty: ->
    _.isEmpty(this)

  eql: (other) ->
    _.isEqual(this, other)

  first: ->
    this[0]

  last: ->
    this[this.length - 1]

  index: (string_or_pattern, start_index = 0) ->
    if string_or_pattern.is_a(RegExp)
      if (index = this.search(string_or_pattern)) != -1
        index
    else if (index = this.indexOf(string_or_pattern, start_index)) != -1
      index

  includes: (string, start_index = 0) ->
    _.includes(this, string, start_index)

  excludes: (string, start_index = 0) ->
    !this.includes(string, start_index)

  safe_text: ->
    _.escape(this)

  safe_regex: ->
    _.escapeRegExp(this)

  downcase: ->
    this.toLowerCase()

  upcase: ->
    this.toUpperCase()

  sub: (pattern, replacement) ->
    _.replace(this, pattern, replacement)

  gsub: (pattern, replacement) ->
    pattern =
      if pattern.is_a(String)
        ///#{pattern.safe_regex()}///g
      else
        {source, flags, global} = pattern
        flags += 'g' unless global
        new RegExp(source, flags)
    _.replace(this, pattern, replacement)

  strip: (chars) ->
    _.trim(this, chars)

  lstrip: (chars) ->
    _.trimStart(this, chars)

  rstrip: (chars) ->
    _.trimEnd(this, chars)

  chop: ->
    this[0..-2]

  center: (length = 0, chars = ' ') ->
    _.pad(this, length, chars)

  ljust: (length = 0, chars = ' ') ->
    _.padEnd(this, length, chars)

  rjust: (length = 0, chars = ' ') ->
    _.padStart(this, length, chars)

  camelize: ->
    _.upperFirst(_.camelCase(this))

  underscore: ->
    this.gsub(/::/, '/')
      .gsub(/([A-Z\d]+)([A-Z][a-z])/, '$1_$2')
      .gsub(/([a-z\d])([A-Z])/, '$1_$2')
      .gsub('-', '_')
      .downcase()

  full_underscore: ->
    this.underscore().gsub(/[\.\/]/, '_').sub(/^_/, '')

  parameterize: ->
    this.gsub(/[^a-z0-9\-_]+/i, '-')
      .gsub(/-{2,}/, '-')
      .gsub(/^-|-$/i, '')
      .downcase()

  humanize: ->
    this[0].upcase() + this.gsub('_', ' ')[1..]

  acronym: ->
    this.camelize().match(/[A-Z]/g)?.join('')

  constantize: ->
    if this.match /[^A-Za-z0-9_:.]+/
      throw "#{this.safe_text()} isn't a valid module or class name"
    else
      eval(this.gsub '::', '.prototype.')

  partition: (separator) ->
    if (index = this.index(separator))?
      [left_start, left_end] = if index then [0, (index - 1)] else [this.length, 0]
      if separator.is_a(RegExp)
        separator = this.match(separator)[0]
      [this[left_start..left_end], separator, this[(index + separator.length)..]]
    else
      [this[0..], '', '']

  prefix_of: (name) ->
    if this.present()
      "#{this}_#{name}"
    else
      name

  start_with: (prefixes...) ->
    prefixes = prefixes.unsplat()
    prefixes.any (prefix) =>
      @match ///^#{prefix.safe_regex()}///

  end_with: (suffixes...) ->
    suffixes = suffixes.unsplat()
    suffixes.any (suffix) =>
      @match ///#{suffix.safe_regex()}$///

  simple_format: ->
    this.gsub /(?:\r\n|\r|\n)/g, '<br>'
