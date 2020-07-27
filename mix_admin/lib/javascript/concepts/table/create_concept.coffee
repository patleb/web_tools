class RailsAdmin.Table.CreateConcept
  constants: ->
    LINK: 'CLASS'
    ROW: 'CLASS'
    CELL: 'CLASS'
    SAVE: 'CLASS'
    CANCEL: 'CLASS'
    CONTENT_STATE: '.table thead'

  document_on: => [
    'click', @LINK, (event, link) =>
      if Main.index_action
        unless link.hasClass('active')
          @show_inputs()
      else
        url = Routes.url_for('new', model_name: Main.model_name)
        $.pjax(url: url)

    'click', @CANCEL, (event) =>
      @clear_inputs()

    'click', @SAVE, (event, target) =>
      return if (@button = target).has_once()

      if $.form_valid(@inputs)
        @send_form()

    'focus', "#{@CELL} input", (event) ->
      RailsAdmin.TableConcept.disable_sort()
  ]

  ready: =>
    @row = $(@ROW)
    @inputs = @row.find('input')

  #### PRIVATE ####

  send_form: =>
    inputs = @inputs.each_with_object {}, (input, result) =>
      result[input.attr('name')] = input.get_value()
    form = $.form_for(inputs)
    url = Routes.url_for('new', model_name: Main.model_name, inline: true)
    $.pjax(
      url: url
      method: 'POST'
      data: form
      push: false
      once: @SAVE
      done: @CONTENT_STATE
      fail: @CONTENT_STATE
      error: (xhr, status, error) ->
        Flash.error(xhr.responseJSON.flash.error)
    )

  show_inputs: =>
    @row.show()
    $('li[class*="_collection_link"]').removeClass('active')
    $('li.new_collection_link').addClass('active')
    $(@CONTENT_STATE).remove_done()
    RailsAdmin.TableConcept.disable_sort()

  clear_inputs: =>
    @inputs.clear_value()
    Flash.clear()
    @row.hide()
    $('li.new_collection_link').removeClass('active')
    $('li.index_collection_link').addClass('active')
    $(@CONTENT_STATE).remove_fail()
    RailsAdmin.TableConcept.enable_sort()
