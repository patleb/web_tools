HTMLElement::old_focus = HTMLElement::focus
HTMLElement::focus = (options) ->
  if @hasAttribute('tabindex')
    @old_focus(options)
  else
    @setAttribute('tabindex', '-1')
    @old_focus(options)
    @removeAttribute('tabindex')
  return
