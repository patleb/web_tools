class RailsAdmin.Form.ModalFormConcept
  constants: =>
    DIALOG: 'ID'
    CANCEL: 'ID'
    SAVE: 'ID'
    NEW: 'CLASS'
    EDIT: 'CLASS'
    EDITABLE: 'CLASS'
    FORM: => "#{@DIALOG} form"

  document_on: => [
    'click', @CANCEL, (event) =>
      $(@DIALOG).modal('hide')

    'click', @SAVE, (event) =>
      form = $(@DIALOG).find('form')
      form.submit()

    'click', @NEW, (event, target) =>
      { params, select_id } = target.data('new')
      url = Routes.url_for('new', params)
      @render_modal(url, select_id)

    'click', @EDIT, (event, target) =>
      { params, select_id } = target.data('edit')
      params = { id: $("##{select_id}").val() }.merge(params)
      url = Routes.url_for('edit', params)
      @render_modal(url, select_id)

    'change', @EDITABLE, (event, target) =>
      edit_link = $("##{@EDITABLE_CLASS}_#{target.attr('id')}")
      edit_link.toggleClass('disabled', target.val().blank())

    'pjax:success', @FORM, (event, pjax, data) =>
      dialog = $(@DIALOG)
      # TODO data only
      @update(dialog.data('select_id'), JSON.safe_parse(data))
      dialog.modal('hide')

    'pjax:error', @FORM, (event, pjax, status, error) =>
      @render_form(pjax.xhr.responseText.presence() || error)
  ]

  render_modal: (url, select_id) =>
    dialog = $(@DIALOG)
    return dialog.modal('show') if dialog.length

    dialog =
      div$ @DIALOG, class: 'modal fade', data: { select_id: select_id },
        div_ '.modal-dialog',
          div_ '.modal-content', [
            div_ '.modal-header', [
              a_ '.close', "×", href: '#', data: { dismiss: 'modal' }
              h3_ '.modal-header-title', '...'
            ]
            div_ '.modal-body', '...'
            div_ '.modal-footer', [
              a_ @CANCEL, href: '#', class: 'btn btn-default', [
                i_ '.fa.fa-times'
                I18n.t('form_cancel').html_safe(true)
              ]
              a_ @SAVE, href: '#', class: 'btn btn-primary', [
                i_ '.fa.fa-check.icon-white'
                I18n.t('form_save').html_safe(true)
              ]
            ]
          ]
    dialog.modal(keyboard: true, backdrop: true, show: true).on('hidden.bs.modal', (event) -> $(this).remove())

    # fix race condition with modal insertion in the dom (Chrome => Team/add a new fan => #modal not found when it should have).
    # Somehow .on('show') is too early, tried it too.
    setTimeout(=>
      $.ajax(
        url: url
        fail: "#{@DIALOG} .modal-content"
        success: (data, status, xhr) =>
          @render_form(data)
      )
    , 200)

  #### PRIVATE ####

  render_form: (view) =>
    dialog = $(@DIALOG)
    body = dialog.find('.modal-body')
    body.html(view)
    form = body.find('form')
    title = dialog.find('.modal-header-title')
    title.text(form.data('title'))
    RailsAdmin.Form.FieldConcept.ready()

  update: (select_id, data) =>
    fields = RailsAdmin.Form.FieldConcept.fields
    if fields.has_key(select_id)
      select = fields[select_id]
      select.update_input(data)
    else
      input = $("##{select_id}")
      RailsAdmin.Form.FieldConcept.SelectElement::update_select(input, data)
