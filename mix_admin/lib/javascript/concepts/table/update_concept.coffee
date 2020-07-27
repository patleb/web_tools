class RailsAdmin.Table.UpdateConcept
  constants: ->
    WRAPPER: 'CLASS'
    READONLY: 'CLASS'

  document_on: => [
    'click', "#{@WRAPPER} input[readonly]", (event, input) =>
      @show_input(input)

    'blur', @WRAPPER, (event, target) =>
      return if (@input_wrapper = target).has_once()

      @input = @input_wrapper.find('input')

      if @input.invalid()
        @show_error()
      else if @input.get_value().to_s() == @input.attr('value')
        @show_text()
      else
        @send_form()
  ]

  ready_once: =>
    $(window).on 'resize.table_update', _.throttle(@reset_width)

  #### PRIVATE ####

  send_form: (field_value) =>
    id = @input.attr('id').to_i()
    url = Routes.url_for('edit', model_name: Main.model_name, id: id, inline: true)
    form = $.form_for("#{@input.attr('name')}": @input.get_value())
    $.ajax(
      url: url
      method: 'PUT'
      data: form
      # TODO dataType: 'json'
      once: @WRAPPER
      fail: @input_wrapper
      done: @input_wrapper
      success: (data, status, xhr) =>
        @input.set_value(data.value)
        @show_text()
      error: (xhr, status, error) =>
        if xhr.responseJSON?
          Flash.render('error', xhr.responseJSON.flash.error)
          @show_error()
    )

  show_error: =>
    @input_wrapper.add_fail()
    @input.attr(placeholder: @input.attr('value'))

  show_text: =>
    Flash.clear()
    @input.attr(readonly: true)
    @input.removeAttr('placeholder')
    @input_wrapper.addClass(@READONLY_CLASS)
    @input_wrapper.remove_fail()
    RailsAdmin.TableConcept.enable_sort()

  show_input: (input) =>
    input_wrapper = input.closest(@WRAPPER)
    @freeze_width(input_wrapper)
    input.attr(readonly: false).click().focus()
    input_wrapper.removeClass(@READONLY_CLASS)
    input_wrapper.remove_done()
    RailsAdmin.TableConcept.disable_sort()

  freeze_width: (input_wrapper) =>
    current_width = input_wrapper.outerWidth()
    input_wrapper.css(width: current_width)

  reset_width: =>
    $(@WRAPPER).removeAttr('style')
