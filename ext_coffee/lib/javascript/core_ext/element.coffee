HTMLElement.define_methods
  valid: ->
    return true if (form = @closest('form')) ? Rails.get(form, 'ujs:formnovalidate-button')
    return true if @formNoValidate
    return @checkValidity() if @checkValidity?
    return @reportValidity() if @reportValidity?
    true

  invalid: ->
    not @valid()
