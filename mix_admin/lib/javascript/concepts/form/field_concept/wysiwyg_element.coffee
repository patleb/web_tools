class RailsAdmin.Form.FieldConcept::WysiwygElement
  constructor: (@input) ->
    @editor = suneditor.create(@input[0],
      katex: katex,
      lang: suneditor.lang[I18n.locale],
      plugins: suneditor.plugins,
      width : '100%',
      height : 'auto',
      minHeight: '480px',
      maxWidth : '640px',
      imageResizing: false,
      imageRotation: false,
      videoResizing: false,
      videoRotation: false,
      videoRatioShow: false,
      videoWidth: '640px',
      videoHeight: '360px',
      buttonList: [
        ['undo', 'redo'],
        # ['font', 'fontSize', 'formatBlock'],
        # ['paragraphStyle'],
        ['bold', 'underline', 'italic', 'strike', 'subscript', 'superscript'],
        # ['fontColor', 'hiliteColor', 'textStyle'],
        ['removeFormat'],
        ['outdent', 'indent', 'blockquote'],
        # ['align', 'lineHeight'],
        ['horizontalRule', 'list', 'table'],
        ['link', 'image', 'video', 'math'],
        # ['audio', 'imageGallery'], # You must add the "imageGalleryUrl".
        ['fullScreen', 'showBlocks', 'codeView'],
        # ['preview', 'print'],
        # ['save', 'template'],
      ],
    )
    @editor.onload = (core, reload) =>
      Js.decorate core, 'cleanHTML', (html, whitelist) ->
        if whitelist == core.pasteTagsWhitelistRegExp
          $(html).map$((e) -> e.text()).reject((text) -> text.blank()).map((text) -> p_(text, escape: false)).join('')
        else
          this.super(html, whitelist)

    @editor.onChange = (contents, core) =>
      if contents.html_blank()
        @input.val('')
      else
        @input.val(contents)

  leave: =>
    @editor.destroy()
