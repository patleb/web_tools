HTMLElement::valid = ->
  return true if (form = @closest('form')) ? Rails.get(form, 'ujs:formnovalidate-button')
  return true if @formNoValidate
  return @checkValidity() if @checkValidity?
  return @reportValidity() if @reportValidity?
  true

HTMLElement::invalid = ->
  not @valid()

Object.defineProperty(HTMLElement::, 'valid', enumerable: false)
Object.defineProperty(HTMLElement::, 'invalid', enumerable: false)
