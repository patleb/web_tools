Object.defineProperty(window, 'scrollTo', {
  value: jest.fn((x, y) => { document.documentElement.scrollTop = y }),
  writable: true
})
Element.prototype.scrollIntoView = jest.fn()

const head_was = ''
const body_was = ''

const dom = {
  setup_document: (content) => {
    let element = document.createElement('html')
    element.innerHTML = content
    document.head.innerHTML = element.querySelector('head').innerHTML
    document.body.innerHTML = element.querySelector('body').innerHTML
    return content
  },
  reset_document: () => {
    document.head.innerHTML = head_was
    document.body.innerHTML = body_was
  },
  children: (element, test) => {
    return Array.from(element.childNodes).filter(node => node.nodeType === Node.ELEMENT_NODE && test(node))
  },
  matches: (element, selector) => {
    let html = document.documentElement
    let fn = html.matchesSelector || html.webkitMatchesSelector || html.msMatchesSelector || html.mozMatchesSelector
    return fn.call(element, selector)
  },
}
global.dom = dom
