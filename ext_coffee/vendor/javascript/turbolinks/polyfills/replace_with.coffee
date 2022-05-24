###
MIT License

Copyright (c) 2019 Atul Ramachandran

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
###
# From https://developer.mozilla.org/en-US/docs/Web/API/ChildNode/replaceWith
ReplaceWithPolyfill = (nodes...) ->
  unless parent = @parentNode
    return
  if (i = nodes.length) is 0
    parent.removeChild(this)
  while i--
    currentNode = nodes[i]
    if typeof currentNode isnt 'object'
      currentNode = this.ownerDocument.createTextNode(currentNode)
    else if currentNode.parentNode
      currentNode.parentNode.removeChild(currentNode)
    if i is 0
      parent.replaceChild(currentNode, this)
    else
      parent.insertBefore(@previousSibling, currentNode)
  return

unless Element::replaceWith
  Element::replaceWith = ReplaceWithPolyfill
unless CharacterData::replaceWith
  CharacterData::replaceWith = ReplaceWithPolyfill
unless DocumentType::replaceWith
  DocumentType::replaceWith = ReplaceWithPolyfill
