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
  setup_events_log: (events) => {
    dom.reset_events_log()
    for (const event_name of events) {
      addEventListener(event_name, (event) => {
        window.events_log.push([event.type, event.data || event.detail])
      }, false)
    }
  },
  reset_events_log: () => {
    window.events_log = []
  },
  events_log: () => {
    return window.events_log.map(([type, data]) => `${type} -- ${data ? JSON.stringify(data): ''}`)
  },
  children: (element, test) => {
    return Array.from(element.childNodes).filter(node => node.nodeType === Node.ELEMENT_NODE && test(node))
  },
  matches: (element, selector) => {
    let html = document.documentElement
    let fn = html.matchesSelector || html.webkitMatchesSelector || html.msMatchesSelector || html.mozMatchesSelector
    return fn.call(element, selector)
  },
  click: (element) => {
    dom.focus(element)
    return element.click()
  },
  focus: (element) => {
    if (element.hasAttribute('tabindex')) {
      element.focus()
    } else {
      element.setAttribute('tabindex', '-1')
      element.focus()
      element.removeAttribute('tabindex')
    }
  },
  on_event: (event_name, { element = window, event_count = 1 } = {}, handler = (e, index) => {}) => {
    let countdown = event_count
    element.addEventListener(event_name, function eventListener(event) {
      if (--countdown === 0) {
        element.removeEventListener(event_name, eventListener, false)
      }
      handler(event, event_count - countdown - 1)
    }, false)
  },
  off_event: (event_name, { element = window, event_count = 1 } = {}) => {
    let countdown = event_count
    while (countdown--) {
      const event = new CustomEvent(event_name, { bubbles: true })
      element.dispatchEvent(event)
    }
  },
}
global.dom = dom
