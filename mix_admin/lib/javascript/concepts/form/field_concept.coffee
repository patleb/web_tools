class RailsAdmin.Form.FieldConcept
  constants: ->
    INPUT: 'CLASS'

  document_on: => [
    'pjax:clone', Js.Pjax.CONTAINER, (event, pjax, contents) =>
      contents.each$ (content) =>
        content.find_all('.sun-editor').remove()
        # TODO do the same with datetimepicker
  ]

  ready_once: ->
    # TODO still have the bug --> happens when quitting pjax
    $rescue_skipped.push '[SUNEDITOR.create.fail] The ID of the suneditor you are trying to create already exists'

  ready: =>
    return unless (fields = $(@INPUT)).length

    @fields = fields.each_with_object {}, (input, memo) =>
      memo[input.attr('id')] = new @["#{input.data('element').camelize()}Element"](input)

    @fields.each_with_object [], (_, field, memo) ->
      unless memo.includes(field.__proto__)
        memo.push(field.__proto__)
        field.ready?()

  leave: =>
    @fields?.each_with_object [], (_, field, memo) ->
      unless memo.includes(field.__proto__)
        memo.push(field.__proto__)
        field.leave?()
