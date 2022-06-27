Object.defineProperty(window, 'scrollTo', {
  value: jest.fn((x, y) => { document.documentElement.scrollTop = y }),
  writable: true
})
Element.prototype.scrollIntoView = jest.fn()

const document_was = { head: document.head, body: document.body }
const form_submit_was = HTMLFormElement.prototype.submit
const anchor_click_was = HTMLAnchorElement.prototype.click

const dom = {
  setup_document: (content) => {
    const html = content instanceof Document ? content : new DOMParser().parseFromString(content, 'text/html')
    for (const { name, value } of Array.prototype.slice.call(html.documentElement.attributes)) {
      document.documentElement.setAttribute(name, value)
    }
    for (const node of ['head', 'body']) {
      document[node].replaceWith(html[node])
    }
    return content
  },
  reset_document: () => {
    for (const { name } of Array.prototype.slice.call(document.documentElement.attributes)) {
      document.documentElement.removeAttribute(name)
    }
    for (const node of ['head', 'body']) {
      document[node].replaceWith(document_was[node])
    }
  },
  stub_click: () => {
    delete HTMLAnchorElement.prototype.click
    HTMLAnchorElement.prototype.click = function(options = {}) {
      dom.fire('click', { target: this, options })
    }
  },
  reset_click: () => {
    HTMLAnchorElement.prototype.click = anchor_click_was
  },
  stub_submit: () => {
    delete HTMLFormElement.prototype.submit
    HTMLFormElement.prototype.submit = function() {
      dom.fire('submit', { target: this })
    }
  },
  reset_submit: () => {
    HTMLFormElement.prototype.submit = form_submit_was
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
  fire: (name, { target = document, cancelable = true, data = {}, options = {} } = {}) => {
    let event = new CustomEvent(name, { bubbles: true, cancelable: cancelable, detail: data })
    event.data = data
    for (const [key, value] of Object.entries(options)) {
      event[key] = value
    }
    target.dispatchEvent(event)
    return event
  },
  $: (selector) => {
    return Array.prototype.slice.call(document.querySelectorAll(selector))
  },
  find: (selector) => {
    return document.querySelector(selector)
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
