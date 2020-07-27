class RailsAdmin.Form.FieldConcept
  constants: ->
    INPUT: 'CLASS'

  ready: =>
    return unless (fields = $(@INPUT)).length

    @fields = fields.each_with_object {}, (input, memo) =>
      unless (element_name = input.data('type'))?.present()
        input_classes = input.classes()
        element_index = input_classes.index(@INPUT_CLASS) + 1 # Next class is the element name
        element_name = input_classes[element_index].sub(/^js_/, '')
      memo[input.attr('id')] = new @["#{element_name.camelize()}Element"](input)

    @fields.each_with_object [], (_, field, memo) ->
      unless memo.includes(field.__proto__)
        memo.push(field.__proto__)
        field.ready?()

  leave: =>
    @fields?.each_with_object [], (_, field, memo) ->
      unless memo.includes(field.__proto__)
        memo.push(field.__proto__)
        field.leave?()
