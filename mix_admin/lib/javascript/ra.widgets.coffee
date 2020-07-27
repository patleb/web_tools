$(document).ready (content) ->

  content = if content then content else $('form')

  return unless content.length # don't waste time otherwise

  # fileupload

  # https://github.com/Simonwep/pickr

  content.find('[data-fileupload]').each ->
    input = this
    $(this).on 'click', ".delete input[type='checkbox']", ->
      $(input).children('.toggle').toggle('slow')

  # fileupload-preview

  content.find('[data-fileupload]').change ->
    input = this
    image_container = $("#" + input.id).parent().children(".preview")
    unless image_container.length
      image_container = $("#" + input.id).parent().prepend($('<img />').addClass('preview').addClass('img-thumbnail')).find('img.preview')
      image_container.parent().find('img:not(.preview)').hide()
    ext = $("#" + input.id).val().split('.').pop().toLowerCase()
    if input.files and input.files[0] and $.inArray(ext, ['gif','png','jpg','jpeg','bmp']) != -1
      reader = new FileReader()
      reader.onload = (e) ->
        image_container.attr "src", e.target.result
      reader.readAsDataURL input.files[0]
      image_container.show()
    else
      image_container.hide()

  # polymorphic-association

  content.find('[data-polymorphic]').each ->
    type_select = $(this)
    field = type_select.parents('.control-group').first()
    object_select = field.find('select').last()
    urls = type_select.data('urls')
    type_select.on 'change', (e) ->
      if $(this).val() is ''
        object_select.html('<option value=""></option>')
      else
        $.ajax
          url: urls[type_select.val()]
          data:
            compact: true
            all: true
          beforeSend: (xhr) ->
            xhr.setRequestHeader("Accept", "application/json")
          success: (data, status, xhr) ->
            html = $('<option></option>')
            $(data).each (i, el) ->
              option = $('<option></option>')
              option.attr('value', el.id)
              option.text(el.label)
              html = html.add(option)
            object_select.html(html)

  # ckeditor

  goCkeditors = ->
    content.find('[data-richtext=ckeditor]').not('.ckeditored').each (index, domEle) ->
      try
        if instance = window.CKEDITOR.instances[this.id]
          instance.destroy(true)
      window.CKEDITOR.replace(this, $(this).data('options'))
      $(this).addClass('ckeditored')

  $editors = content.find('[data-richtext=ckeditor]').not('.ckeditored')
  if $editors.length
    if not window.CKEDITOR
      options = $editors.first().data('options')
      window.CKEDITOR_BASEPATH = options['base_location']
      $.getScript options['jspath'], (script, textStatus, jqXHR) =>
        goCkeditors()
    else
      goCkeditors()

  #codemirror

  goCodeMirrors = (array) =>
    array.each (index, domEle) ->
      options = $(this).data('options')
      textarea = this
      $.getScript options['locations']['mode'], (script, textStatus, jqXHR) ->
        $('head').append('<link href="' + options['locations']['theme'] + '" rel="stylesheet" media="all" type="text\/css">')
        CodeMirror.fromTextArea(textarea,options['options'])
        $(textarea).addClass('codemirrored')

  array = content.find('[data-richtext=codemirror]').not('.codemirrored')
  if array.length
    @array = array
    if not window.CodeMirror
      options = $(array[0]).data('options')
      $('head').append('<link href="' + options['csspath'] + '" rel="stylesheet" media="all" type="text\/css">')
      $.getScript options['jspath'], (script, textStatus, jqXHR) =>
        goCodeMirrors(@array)
    else
      goCodeMirrors(@array)

  # bootstrap_wysihtml5

  goBootstrapWysihtml5s = (array, config_options) =>
    array.each ->
      $(@).addClass('bootstrap-wysihtml5ed')
      $(@).closest('.controls').addClass('well')
      $(@).wysihtml5(config_options)

  array = content.find('[data-richtext=bootstrap-wysihtml5]').not('.bootstrap-wysihtml5ed')
  if array.length
    @array = array
    options = $(array[0]).data('options')
    config_options = $.parseJSON(options['config_options'])
    if not window.wysihtml5
      $('head').append('<link href="' + options['csspath'] + '" rel="stylesheet" media="all" type="text\/css">')
      $.getScript options['jspath'], (script, textStatus, jqXHR) =>
        goBootstrapWysihtml5s(@array, config_options)
    else
      goBootstrapWysihtml5s(@array, config_options)

  # froala_wysiwyg

  goFroalaWysiwygs = (array) =>
    array.each ->
      options = $(@).data('options')
      config_options = $.parseJSON(options['config_options'])
      if config_options
        if !config_options['inlineMode']
          config_options['inlineMode'] = false
      else
        config_options = { inlineMode: false }

      uploadEnabled =
      if config_options['imageUploadURL']
        config_options['imageUploadParams'] =
          authenticity_token: $('meta[name=csrf-token]').attr('content')

      $(@).addClass('froala-wysiwyged')
      $(@).editable(config_options)
      if uploadEnabled
        $(@).on 'editable.imageError', (e, editor, error) ->
          alert("error uploading image: " + error.message);
          # Custom error message returned from the server.
          if error.code == 0

          # Bad link.
          else if error.code == 1

          # No link in upload response.
          else if error.code == 2

          # Error during image upload.
          else if error.code == 3

          # Parsing response failed.
          else if error.code == 4

          # Image too large.
          else if error.code == 5

          # Invalid image type.
          else if error.code == 6

          # Image can be uploaded only to same domain in IE 8 and IE 9.
          else if error.code == 7

          else

          return

        .on('editable.afterRemoveImage', (e, editor, $img) ->
          # Set the image source to the image delete params.
          editor.options.imageDeleteParams =
            src: $img.attr('src')
            authenticity_token: $('meta[name=csrf-token]').attr('content')
          # Make the delete request.
          editor.deleteImage $img
          return
        ).on('editable.imageDeleteSuccess', (e, editor, data) ->
          # handle success
        ).on 'editable.imageDeleteError', (e, editor, error) ->
          # handle error
          alert("error deleting image: " + error.message);

  array = content.find('[data-richtext=froala-wysiwyg]').not('.froala-wysiwyged')
  if array.length
    options = $(array[0]).data('options')
    if not $.isFunction($.fn.editable)
      $('head').append('<link href="' + options['csspath'] + '" rel="stylesheet" media="all" type="text\/css">')
      $.getScript options['jspath'], (script, textStatus, jqXHR) =>
        goFroalaWysiwygs(array)
    else
      goFroalaWysiwygs(array)
