class RailsAdmin.Form.FieldConcept
  constants: ->
    INPUT: 'CLASS'

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
