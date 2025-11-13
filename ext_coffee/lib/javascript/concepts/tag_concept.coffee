class Js.TagConcept
  global: true

  ID_CLASSES = /^([#.][A-Za-z_-][:\w-]*)+$/

  HTML_TAGS: [
    'a'
    'button'
    'datalist', 'dd', 'div', 'dl', 'dt'
    'fieldset', 'form'
    'i', 'input'
    'label', 'li'
    'ol', 'optgroup', 'option'
    'select', 'span'
    'textarea', 'time'
    'ul'
  ].to_set()

  ready_once: ->
    window.h_ = @h_
    window.if_ = @if_
    window.unless_ = @unless_
    @HTML_TAGS.each (tag) => @define_tag(tag)

  define: (tags...) ->
    @merge(tags...)
    tags.each (tag) => @define_tag(tag)

  merge: (tags...) ->
    @HTML_TAGS.merge(tags.to_set())

  h_: (values...) =>
    if values.length is 1 and (text = values[0])?.is_a Function
      values = [text()]
    values = values.flatten().compact().map (item) ->
      item = ''.html_safe(true) unless item?
      item = item.safe_text()   unless item.html_safe()
      item.to_s()
    values = values.join(' ')
    values.html_safe(true)

  if_: (is_true, values...) =>
    return ''.html_safe(true) unless @continue(if: is_true)
    @h_(values...)

  unless_: (is_true, values...) =>
    return ''.html_safe(true) unless @continue(unless: is_true)
    @h_(values...)

  # Private

  define_tag: (tag) ->
    tag_ = "#{tag}_"
    tag$ = "#{tag}$"
    window[tag_] ?= (args...) => @with_tag(tag_, args...)
    window[tag$] ?= (args...) => @with_tag(tag$, args...)

  with_tag: (tag, [css_or_content_or_options, content_or_options, options_or_content]...) ->
    if css_or_content_or_options?
      if css_or_content_or_options.is_a(String) and css_or_content_or_options.match ID_CLASSES
        id_classes = css_or_content_or_options
        if content_or_options?
          if content_or_options.is_a Object
            content = options_or_content
            options = content_or_options
          else
            content = content_or_options
            options = options_or_content
      else if css_or_content_or_options.is_a Object
        content = content_or_options
        options = css_or_content_or_options
      else
        content = css_or_content_or_options
        options = content_or_options if content_or_options?.is_a Object
    options = if options? then options.dup() else {}

    return ''.html_safe(true) unless @continue(options)

    if id_classes
      [id, classes] = @parse_id_classes(id_classes)
      options.id ||= id
      options.class = @merge_classes(options, classes)

    if (classes = options.class)
      options.class = @classes_to_string(classes)
      options.delete('class') if options.class.blank()

    if options.data?.is_a Object
      { data: options.delete('data') }.flatten_keys('-').each (key, value) ->
        options[key] = value

    element = true if tag.last() is '$'
    tag = tag.chop()

    escape = options.delete('escape') ? true
    content = options.delete('text') if options.text?
    content = content() if content?.is_a Function
    switch tag
      when 'a'
        options.rel = 'noopener' unless options.rel
        options['data-turbolinks'] = options.delete('turbolinks')
      when 'button'
        options.type ?= 'submit'
      when 'input'
        options.autocomplete ?= 'off' if options.type is 'hidden'
      when 'select'
        options.autocomplete ?= 'off' if options.name or options.id
    content = @h_(content) if content?.is_a Array
    content ?= ''.html_safe(true)
    result = if tag? then @content_tag(tag, content, options, escape) else @h_(content)
    result = result.to_s().html_safe(true) unless element
    result

  merge_classes: (options, classes) ->
    if options.has_key 'class'
      old_array = @classes_to_array(options.class)
      new_array = @classes_to_array(classes)
      new_array.union(old_array)
    else
      @classes_to_array(classes)

  # Private

  parse_id_classes: (string) ->
    [classes, _separator, id_classes] = string.partition('#')
    classes = classes.split('.')
    if id_classes
      [id, other_classes...] = id_classes.split('.')
      classes.merge(other_classes)
    [id, classes]

  classes_to_array: (classes) ->
    if classes?.is_a Object
      @classes_to_array(classes.select_map (value, condition) -> value if condition)
    else if classes?.is_a Array
      classes
    else
      classes?.split(' ') or []

  classes_to_string: (classes) ->
    if classes?.is_a Object
      classes.select_map((value, condition) -> value if condition).join(' ')
    else if classes?.is_a Array
      classes.compact_blank().join(' ')
    else
      classes

  content_tag: (tag, text, options, escape) ->
    tag = document.createElement(tag)
    options.class = options.delete('class') # necessary to keep #id.classes order
    cast = options['data-cast']?.presence()
    for name, value of options
      if value?
        if cast and name is 'value' and not value.html_safe()
          options['data-cast'] = type_caster(value) if cast is true
          value = value.safe_text()
        tag.setAttribute(name, value)
    if escape and not text.html_safe()
      tag.textContent = text.safe_text()
    else
      tag.innerHTML = text.to_s()
    tag

  continue: (options = {}) ->
    if options.has_key 'if'
      is_true = options.delete('if')
      is_true = is_true() if is_true?.is_a Function
      return false unless is_true
    if options.has_key 'unless'
      is_true = options.delete('unless')
      is_true = is_true() if is_true?.is_a Function
      return false if is_true
    true
