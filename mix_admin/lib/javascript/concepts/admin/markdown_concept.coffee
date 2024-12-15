class Js.Admin.MarkdownConcept
  MAX_HISTORY_SIZE = 25

  constants: ->
    TEXTAREA: '.js_markdown'
    TOOLBAR: '.js_markdown_toolbar'
    FILE_INPUT: '.js_markdown_file'
    MAX_FILE_SIZE: '.js_markdown_max_file_size'

  document_on: -> [
    'click', "#{@TOOLBAR} .js_fullscreen", @toggle_fullscreen
    'change', @TEXTAREA,                   @push_history
    'click', "#{@TOOLBAR} .js_undo",       @undo_history
    'click', "#{@TOOLBAR} .js_redo",       @redo_history
    'click', "#{@TOOLBAR} .js_bold",       (event, target) -> @wrap_text target, '**'
    'click', "#{@TOOLBAR} .js_italic",     (event, target) -> @wrap_text target, '*'
    'click', "#{@TOOLBAR} .js_blockquote", (event, target) -> @prepend_lines target, '> '
    'click', "#{@TOOLBAR} .js_code",       (event, target) -> @wrap_text target, '`'
    'click', "#{@TOOLBAR} .js_bulletlist", (event, target) -> @prepend_lines target, '- '
    'click', "#{@TOOLBAR} .js_link",       @link_text
    'click', "#{@TOOLBAR} .js_multimedia", @select_file
    'change',            @FILE_INPUT,      @compute_file_uid
    'blob:uid:computed', @FILE_INPUT,      @fetch_blob_id
    'blob:id:not_found', @FILE_INPUT,      @upload_file
    'blob:id:found',     @FILE_INPUT,      @link_image
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

  wrap_text: (button, token) ->
    [textarea, text, start, end] = @selection_text(button)
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
    value_undo = undo.last()
    if value isnt value_undo
      redo.clear(true)
      undo.shift() if undo.length is MAX_HISTORY_SIZE
      value_was = push[0]
      undo.push(value_was) if value_was not in [value_undo, value]
      undo.push(value)
    push[0] = value

  undo_history: (event, button) ->
    textarea = @textarea(button)
    { push, undo, redo } = @get_history(textarea)
    value = textarea.get_value()
    if (value_was = undo.pop())?
      redo.push(value) if value?
      if value_was is value
        value_was = undo.pop()
      push[0] = textarea.set_value(value_was) if value_was?
    textarea.focus()

  redo_history: (event, button) ->
    textarea = @textarea(button)
    { push, undo, redo } = @get_history(textarea)
    value = textarea.get_value()
    if (value_was = redo.pop())?
      undo.push(value) if value?
      if value_was is value
        value_was = redo.pop()
      push[0] = textarea.set_value(value_was) if value_was?
    textarea.focus()

  select_file: (event, button) ->
    unless (file_input = button.find(@FILE_INPUT))
      file_input = input$ @FILE_INPUT, type: 'file', accept: 'image/*', style: 'display:none'
      button.appendChild(file_input)
    file_input.click()

  compute_file_uid: (event, file_input) ->
    return unless (file = file_input.files[0])
    return unless @valid file
    @read(file)
      .then (result) ->
        result = new Uint8Array(result)
        window.crypto.subtle.digest('SHA-256', result)
      .then (result) ->
        uid = [btoa(file.name), btoa(String.fromCharCode(new Uint8Array(result)...))].join(',')
        Rails.fire file_input, 'blob:uid:computed', { file, uid }

  fetch_blob_id: ({ detail: { file, uid } }, file_input) ->
    Rails.ajax({
      type: 'GET'
      url: Routes.path_for('upload', { model_name: Js.AdminConcept.model(), blob: { uid } })
      data_type: 'json'
      success: (response) ->
        if (id = response.blob.id)
          Rails.fire file_input, 'blob:id:found', { id, filename: file.name }
        else
          Rails.fire file_input, 'blob:id:not_found', { file }
      error: =>
        @on_file_error(file_input)
    })

  upload_file: ({ detail: { file } }, file_input) ->
    data = new FormData()
    data.append('blob[filename]', file.name)
    data.append('blob[data]', file)
    Rails.ajax({
      type: 'POST'
      url: Routes.path_for('upload', { model_name: Js.AdminConcept.model() })
      data
      data_type: 'json'
      success: (response) ->
        Rails.fire file_input, 'blob:id:found', { id: response.blob.id, filename: file.name }
      error: =>
        @on_file_error(file_input)
    })

  link_image: ({ detail: { id, filename } }, file_input) ->
    [textarea, text, start, end] = @selection_text(file_input)
    file_input.remove()
    text ||= filename
    text = "![#{text}](image:#{id})"
    textarea.setRangeText(text, start, end)
    textarea.focus()
    textarea.cursor_start(start + text.length)
    Rails.fire textarea, 'change'

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
    text = if start is end then '' else textarea.value[start..(end - 1)]
    [textarea, text, start, end]

  start_end: (textarea) ->
    [textarea.cursor_start(), textarea.cursor_end()]

  textarea: (target) ->
    target.closest(@TOOLBAR).next()

  get_history: (textarea) ->
    name = textarea.getAttribute('name')
    (@history ?= {})[name] ?= { push: [textarea.value], undo: [], redo: [] }

  read: (file) ->
    new Promise (resolve, _reject) ->
      reader = new FileReader()
      reader.onload = => resolve(reader.result)
      reader.readAsArrayBuffer(file)

  valid: (file) ->
    unless file.size < @max_file_size
      Flash.alert "File too large: must be < #{@max_file_size} bytes"
      return false
    unless file.type.start_with('image/')
      Flash.alert "File must be an image"
      return false
    true

  on_file_error: (file_input) ->
    Flash.alert 'Server Error'
    file_input.remove()
