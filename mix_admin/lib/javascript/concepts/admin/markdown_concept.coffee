class Js.Admin.MarkdownConcept
  MAX_HISTORY_SIZE = 25

  constants: ->
    TEXTAREA: '.js_markdown'
    TOOLBAR: '.js_markdown_toolbar'

  document_on: -> [
    'change', @TEXTAREA, (event, target) ->
      @push_history target

    'click', "#{@TOOLBAR} .js_fullscreen", (event, target) ->
      return document.exitFullscreen() if document.fullscreenElement
      field = target.closest('.field')
      field.requestFullscreen().catch (error) ->
        Flash.alert "#{error.name}: #{error.message}"

    'click', "#{@TOOLBAR} .js_undo", (event, target) ->
      textarea = @textarea(target)
      @undo_history textarea

    'click', "#{@TOOLBAR} .js_redo", (event, target) ->
      textarea = @textarea(target)
      @redo_history textarea

    'click', "#{@TOOLBAR} .js_bold", (event, target) ->
      @wrap_text target, '**'

    'click', "#{@TOOLBAR} .js_italic", (event, target) ->
      @wrap_text target, '*'

    'click', "#{@TOOLBAR} .js_blockquote", (event, target) ->
      @prepend_lines target, '> '

    'click', "#{@TOOLBAR} .js_code", (event, target) ->
      @wrap_text target, '`'

    'click', "#{@TOOLBAR} .js_link", (event, target) ->
      @link_text target

    'click', "#{@TOOLBAR} .js_bulletlist", (event, target) ->
      @prepend_lines target, '- '

    'click', "#{@TOOLBAR} .js_multimedia", (event, target) ->

  ]

  ready: ->
    Rails.$(@TEXTAREA).each (textarea) =>
      @get_history(textarea)

  prepend_lines: (target, token) ->
    [textarea, lines, start_i, end_i] = @selection_lines(target)
    size = token.length
    lines[start_i..end_i].each (line, i) ->
      lines[start_i + i] = if line.start_with(token)
        line[size..-1]
      else
        [token, line].join('')
    textarea.set_value(lines.join("\n"), event: true)
    textarea.focus()

  link_text: (target) ->
    [textarea, text, start, end] = @selection_text(target)
    return unless (text_size = text.length)
    text = "[#{text}]()"
    textarea.setRangeText(text, start, end)
    textarea.focus()
    textarea.cursor_start(start + text_size + 3)

  wrap_text: (target, token) ->
    [textarea, text, start, end] = @selection_text(target)
    size = token.length
    if text
      text = if size * 2 <= text.length and text.start_with(token) and text.end_with(token)
        text[size..(-1 - size)]
      else
        [token, text, token].join('')
      textarea.focus()
      textarea.setRangeText(text, start, end)
    else
      textarea.setRangeText([token, token].join(''), start, end)
      textarea.focus()
      textarea.cursor_start(start + size)
    Rails.fire(textarea, 'change')

  push_history: (textarea) ->
    { push, undo, redo } = @get_history(textarea)
    value = textarea.get_value()
    value_undo = undo.last()
    if value isnt value_undo
      redo.clear(true)
      undo.shift() if undo.length is MAX_HISTORY_SIZE
      value_was = push[0]
      undo.push(value_was) if value_was not in [value_undo, value]
      undo.push(value)
    push[0] = value

  undo_history: (textarea) ->
    { push, undo, redo } = @get_history(textarea)
    value = textarea.get_value()
    if (value_was = undo.pop())?
      redo.push(value) if value?
      if value_was is value
        value_was = undo.pop()
      push[0] = textarea.set_value(value_was) if value_was?
    textarea.focus()

  redo_history: (textarea) ->
    { push, undo, redo } = @get_history(textarea)
    value = textarea.get_value()
    if (value_was = redo.pop())?
      undo.push(value) if value?
      if value_was is value
        value_was = redo.pop()
      push[0] = textarea.set_value(value_was) if value_was?
    textarea.focus()

  # Private

  selection_lines: (target) ->
    textarea = @textarea(target)
    lines = textarea.value.split("\n")
    [start, end] = @start_end(textarea)
    [start_i, end_i] = [null, null]
    position = 0
    lines.each (line, i) ->
      start_i = i if start >= position
      end_i = i if end >= position
      position += line.length + 1
    start_i ?= lines.length - 1
    end_i ?= lines.length - 1
    [textarea, lines, start_i, end_i]

  selection_text: (target) ->
    textarea = @textarea(target)
    [start, end] = @start_end(textarea)
    [textarea, textarea.value[start..(end - 1)], start, end]

  start_end: (textarea) ->
    [textarea.cursor_start(), textarea.cursor_end()]

  textarea: (target) ->
    target.closest(@TOOLBAR).next()

  get_history: (textarea) ->
    name = textarea.getAttribute('name')
    (@history ?= {})[name] ?= { push: [textarea.value], undo: [], redo: [] }
