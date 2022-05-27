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
  $: (selector) => {
    return Array.prototype.slice.call(document.querySelectorAll(selector))
  },
  children: (element, test) => {
    return Array.from(element.childNodes).filter(node => node.nodeType === Node.ELEMENT_NODE && test(node))
  },
  on_event: ({ element = window, count = 1, ...rest } = {}) => {
    const [event_name, handler] = Object.entries(rest)[0]
    let countdown = count
    element.addEventListener(event_name, function eventListener(event) {
      if (--countdown === 0) {
        element.removeEventListener(event_name, eventListener, false)
      }
      handler(event, count - countdown - 1)
    }, false)
  },
  off_event: (event_name, { element = window, count = 1 } = {}) => {
    let countdown = count
    while (countdown--) {
      const event = new CustomEvent(event_name, { bubbles: true })
      element.dispatchEvent(event)
    }
  },
}
global.dom = dom
