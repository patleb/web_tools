class RailsAdmin.Form.FieldConcept::WysiwygElement
  constructor: (@input) ->
    @editor = suneditor.create(@input[0],
      katex: katex,
      lang: suneditor.lang[I18n.locale],
      plugins: suneditor.plugins,
      width : '100%',
      height : 'auto',
      minHeight: '400px',
      maxWidth : '600px',
      buttonList: [
        ['undo', 'redo'],
        ['bold', 'underline', 'italic', 'strike', 'subscript', 'superscript'],
        ['removeFormat'],
        ['outdent', 'indent'],
        ['fullScreen', 'showBlocks', 'codeView'],
        # ['preview', 'print'],
        ['list', 'table'],
        ['link', 'image', 'math'],
      ],
    )
    @editor.onChange = (contents, core) =>
      if contents.gsub(/(<\/?p>|&nbsp;|<br>)/, '').blank()
        @input.val('')
      else
        @input.val(contents)

  leave: =>
    @editor.destroy()
