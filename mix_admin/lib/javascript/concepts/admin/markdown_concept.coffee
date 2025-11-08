class Js.Admin.MarkdownConcept
  MAX_HISTORY_SIZE = 25

  constants: ->
    TEXTAREA: '.js_markdown'
    TOOLBAR: '.js_markdown_toolbar'
    FILE_INPUT: '.js_markdown_file'
    MAX_FILE_SIZE: '.js_markdown_max_file_size'

  events: -> [
    'click', "#{@TOOLBAR} .js_fullscreen", @toggle_fullscreen
    'change', @TEXTAREA,                   @push_history
    'click', "#{@TOOLBAR} .js_undo",       @undo_history
    'click', "#{@TOOLBAR} .js_redo",       @redo_history
    'click', "#{@TOOLBAR} .js_bold",       (event, target) -> @wrap_text target, '**'
    'click', "#{@TOOLBAR} .js_italic",     (event, target) -> @wrap_text target, '*'
    'click', "#{@TOOLBAR} .js_blockquote", (event, target) -> @prepend_lines target, '> '
    'click', "#{@TOOLBAR} .js_code",       (event, target) -> @wrap_text target, '`', multiline: '```'
    'click', "#{@TOOLBAR} .js_link",       @link_text
    'click', "#{@TOOLBAR} .js_bulletlist", (event, target) -> @prepend_lines target, '- '
    'click', "#{@TOOLBAR} .js_multimedia", @select_file
    'change', @FILE_INPUT,                 @link_image
  ]

  ready: ->
    @max_file_size = Rails.find(@MAX_FILE_SIZE)?.data('value')?.to_i() ? 10000000
    Rails.$(@TEXTAREA).each (textarea) =>
      @get_history(textarea)

  toggle_fullscreen: (event, button) ->
    return document.exitFullscreen() if document.fullscreenElement
    field = button.closest('.field')
    field.requestFullscreen().catch (error) ->
      Flash.alert "#{error.name}: #{error.message}"

  wrap_text: (button, token, { multiline = false } = {}) ->
    [textarea, text, start, end] = @selection_text(button)
    size = token.length
    if text
      token_start = token_end = token
      if multiline and text.include("\n")
        token = multiline
        [token_start, token_end] = ["#{token}\n", "\n#{token}"]
        size = token_start.length
      text = if size * 2 <= text.length and text.start_with(token_start) and text.end_with(token_end)
        text[size..(-1 - size)]
      else
        [token_start, text, token_end].join('')
      textarea.focus()
      textarea.setRangeText(text, start, end)
    else
      textarea.setRangeText([token, token].join(''), start, end)
      textarea.focus()
      textarea.cursor_start(start + size)
    Rails.fire textarea, 'change'

  prepend_lines: (button, token) ->
    [textarea, lines, start_i, end_i] = @selection_lines(button)
    size = token.length
    lines[start_i..end_i].each (line, i) ->
      lines[start_i + i] = if line.start_with(token)
        line[size..-1]
      else
        [token, line].join('')
    textarea.set_value(lines.join("\n"), event: true)
    textarea.focus()

  link_text: (event, button) ->
    [textarea, text, start, end] = @selection_text(button)
    return unless (text_size = text.length)
    text = "[#{text}]()"
    textarea.setRangeText(text, start, end)
    textarea.focus()
    textarea.cursor_start(start + text_size + 3)
    Rails.fire textarea, 'change'

  push_history: (event, textarea) ->
    { push, undo, redo } = @get_history(textarea)
    value = textarea.get_value()
    [value_undo, cursor_undo] = Array.wrap(undo.last())
    if value isnt value_undo
      redo.clear(true)
      undo.shift() if undo.length is MAX_HISTORY_SIZE
      [value_was, cursor_was] = push[0]
      undo.push([value_was, cursor_was]) if value_was not in [value_undo, value]
      undo.push([value, textarea.cursor_end()])
    push[0] = [value, textarea.cursor_end()]

  undo_history: (event, button) ->
    textarea = @textarea(button)
    { push, undo, redo } = @get_history(textarea)
    @pop_history(textarea, push, undo, redo)

  redo_history: (event, button) ->
    textarea = @textarea(button)
    { push, undo, redo } = @get_history(textarea)
    @pop_history(textarea, push, redo, undo)

  select_file: (event, button) ->
    unless (file_input = button.find(@FILE_INPUT))
      file_input = input$ @FILE_INPUT, type: 'file', accept: 'image/*', style: 'display:none'
      button.appendChild(file_input)
    file_input.click()

  link_image: (event, file_input) ->
    button = file_input.closest('.js_multimedia')
    file = file_input.files[0]
    file_input.remove()
    return unless @valid file
    @read(file)
      .then (result) ->
        result = new Uint8Array(result)
        window.crypto.subtle.digest('SHA-256', result)
      .then (result) =>
        uid = [btoa(file.name), btoa(String.fromCharCode(new Uint8Array(result)...))].join(',')
        @fetch_blob_id(button, file, uid)

  fetch_blob_id: (button, file, uid) ->
    Rails.ajax({
      type: 'GET'
      url: Routes.path_for('upload', { model_name: Js.AdminConcept.model, blob: { uid } })
      data_type: 'json'
      success: (response) =>
        if (id = response.blob.id)
          @link_blob(button, id, file.name)
        else
          @upload_file(button, file)
      error: =>
        @on_file_error()
    })

  upload_file: (button, file) ->
    textarea = @textarea(button)
    data = new FormData()
    data.append('blob[filename]', file.name)
    data.append('blob[data]', file)
    Rails.ajax({
      type: 'POST'
      url: Routes.path_for('upload', { model_name: Js.AdminConcept.model })
      data
      data_type: 'json'
      beforeSend: ->
        Rails.disable_elements button, textarea
        Js.load_spinner()
        true
      success: (response) =>
        @link_blob(button, response.blob.id, file.name)
      error: =>
        @on_file_error()
      complete: ->
        Rails.enable_elements button, textarea
        Js.clear_spinner()
    })

  link_blob: (button, id, filename) ->
    [textarea, text, start, end] = @selection_text(button)
    text ||= filename
    text = "![#{text}](blob:#{id})"
    textarea.setRangeText(text, start, end)
    textarea.focus()
    textarea.cursor_start(start + text.length)
    Rails.fire textarea, 'change'

  # Private

  selection_lines: (button) ->
    textarea = @textarea(button)
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

  selection_text: (button) ->
    textarea = @textarea(button)
    [start, end] = @start_end(textarea)
    text = if start is end then '' else textarea.value[start..(end - 1)]
    [textarea, text, start, end]

  start_end: (textarea) ->
    [textarea.cursor_start(), textarea.cursor_end()]

  textarea: (button) ->
    button.closest(@TOOLBAR).next()

  pop_history: (textarea, push, undo, redo) ->
    value = textarea.get_value()
    [value_was, cursor_was] = Array.wrap(undo.pop())
    if value_was?
      redo.push([value, textarea.cursor_end()]) if value?
      if value_was is value
        [value_was, cursor_was] = Array.wrap(undo.pop())
      push[0] = [textarea.set_value(value_was), cursor_was] if value_was?
    textarea.cursor_end(cursor_was)
    textarea.focus()

  get_history: (textarea) ->
    name = textarea.getAttribute('name')
    (@history ?= {})[name] ?= { push: [[textarea.value, textarea.cursor_end()]], undo: [], redo: [] }

  read: (file) ->
    new Promise (resolve) ->
      reader = new FileReader()
      reader.onload = -> resolve(reader.result)
      reader.readAsArrayBuffer(file)

  valid: (file) ->
    return false unless file
    unless file.size < @max_file_size
      Flash.alert "File too large: must be < #{@max_file_size} bytes"
      return false
    unless file.type.start_with('image/')
      Flash.alert "File must be an image"
      return false
    true

  on_file_error: ->
    Flash.alert 'Server Error'
