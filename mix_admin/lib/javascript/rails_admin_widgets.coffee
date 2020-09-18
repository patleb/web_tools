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
