jQueryTags = jQuery.fn.init
jQuery.fn.init = (selector, context, root) ->
  if selector?.html_safe?()
    selector = selector.to_s()
  new jQueryTags(selector, context, root)
