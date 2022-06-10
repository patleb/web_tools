m = Element::matches or
  Element::matchesSelector or
  Element::mozMatchesSelector or
  Element::msMatchesSelector or
  Element::oMatchesSelector or
  Element::webkitMatchesSelector

# Checks if the given native dom element matches the selector
# element::
#   native DOM element
# selector::
#   CSS selector string or
#   a JavaScript object with `selector` and `exclude` properties
#   Examples: "form", { selector: "form", exclude: "form[data-remote='true']"}
Element::matches = (selector) ->
  if typeof selector is 'object' and selector.exclude?
    m.call(this, selector.selector) and not m.call(this, selector.exclude)
  else
    m.call(this, selector)
