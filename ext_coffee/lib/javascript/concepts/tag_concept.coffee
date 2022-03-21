class Js.TagConcept
  ID_CLASSES = /^([#.][A-Za-z][\w-]*)+$/
  HTML_TAGS = [
    'a'
    'b', 'button'
    'dd', 'div', 'dl', 'dt'
    'em'
    'fieldset', 'form'
    'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'hr'
    'i', 'input'
    'label', 'legend', 'li'
    'nav'
    'option'
    'p', 'pre'
    'select', 'span', 'strong'
    'table', 'tbody', 'td', 'th', 'thead', 'tr'
    'ul'
  ]

  constants: ->
    NAMES: 'ID'

  ready_once: =>
    @define_tags()

  #### PRIVATE ####

  define_tags: (tags) =>
    window.h_ = @h_
    window.h_if = @h_if
    window.h_unless = @h_unless
    HTML_TAGS.each (tag) =>
      window["#{tag}_"] ?= (args...) =>
        @with_tag(tag, args...)
      tag$ = "#{tag}$"
      window[tag$] ?= (args...) =>
        @with_tag(tag$, args...)

  h_: (values...) =>
    if values.length == 1 && (text = values[0])?.is_a(Function)
      values = [text()]
    values = values.flatten().compact().map (item) ->
      item = item.safe_text() unless item.html_safe()
      item
    values = values.join(' ')
    values.html_safe(true)

  h_if: (is_true, values...) =>
    return '' unless @continue(if: is_true)
    @h_(values...)

  h_unless: (is_true, values...) =>
    return '' unless @continue(unless: is_true)
    @h_(values...)

  with_tag: (tag, [css_or_text_or_options, text_or_options, options_or_text]...) =>
    if css_or_text_or_options?
      if css_or_text_or_options.is_a(String) && css_or_text_or_options.match(ID_CLASSES)
        id_classes = css_or_text_or_options
        if text_or_options?
          if text_or_options.is_a(Object)
            text = options_or_text
            options = text_or_options
          else
            text = text_or_options
            options = options_or_text
      else if css_or_text_or_options.is_a(Object)
        text = text_or_options
        options = css_or_text_or_options
      else
        text = css_or_text_or_options
        options = text_or_options
    options = if options? then options.dup() else {}

    return '' unless @continue(options)

    if id_classes
      [id, classes] = @parse_id_classes(id_classes)
      options.id ||= id
      options = @merge_classes(options, classes)

    if options.class?.is_a(Array)
      options.class = options.class.select((item) -> item?.present()).join(' ')
      options.delete('class') if options.class.blank()

    if options.data?.is_a(Object)
      # TODO validate this is a wanted behavior, instead of keeping underscores
      { data: options.delete('data') }.flatten_keys().each (key, value) ->
        options[key] = value

    escape = options.delete('escape') ? true
    text = options.delete('text') if options.text?
    text = text() if text?.is_a(Function)
    text = @h_(text) if text?.is_a(Array)

    @content_tag(tag, text ? '', options, escape)

  parse_id_classes: (string) ->
    [classes, _separator, id_classes] = string.partition('#')
    classes = classes.split('.')
    if id_classes
      [id, other_classes...] = id_classes.split('.')
      classes = classes.concat(other_classes)
    [id, classes]

  merge_classes: (options, classes) =>
    if options.has_key('class')
      options.merge class: classes, (old_val, new_val, key) =>
        if key == 'class'
          old_array = @classes_to_array(old_val)
          new_array = @classes_to_array(new_val)
          new_array.union(old_array)
    else
      options.class = @classes_to_array(classes)
      options

  classes_to_array: (classes) ->
    if classes?.is_a(Array)
      classes
    else
      classes?.split(' ') || []

  content_tag: (tag, text, options, escape) =>
    if tag[-1..] == '$'
      jquery = true
      tag = tag.chop()
    options.class = options.delete('class') # necessary to keep #id.classes order
    tag = $("<#{tag}>", options)
    if escape && !text.html_safe()
      tag.text(text.safe_text())
    else
      tag.html(text.to_s())
    if jquery
      tag
    else
      tag.to_s().html_safe(true)

  continue: (options = {}) ->
    if options.has_key('if')
      is_true = options.delete('if')
      is_true = is_true() if is_true?.is_a(Function)
      return false unless is_true
    if options.has_key('unless')
      is_true = options.delete('unless')
      is_true = is_true() if is_true?.is_a(Function)
      return false if is_true
    true
