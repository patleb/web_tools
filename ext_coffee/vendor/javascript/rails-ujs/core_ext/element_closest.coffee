Element::closest ?= (selector) ->
  node = this
  while node
    return node if node.nodeType is Node.ELEMENT_NODE and node.matches(selector)
    node = node.parentNode
