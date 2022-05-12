import * as assert from '@@lib/ext_webpacker/jest/assertions'
import * as fixture from '@@lib/ext_webpacker/jest/fixtures'
import * as matchers from 'jest-extended'
import xhr from 'xhr-mock'

global.assert = assert
global.fixture = fixture
global.xhr = xhr
expect.extend(matchers)

if (process.env.JB_PUBLISH_PORT != null) {
  jest.setTimeout(2147483647)
}

Object.defineProperty(window, 'scrollTo', {
  value: jest.fn((x, y) => { document.documentElement.scrollTop = y }),
  writable: true
})
Element.prototype.scrollIntoView = jest.fn()

let window_location_was = window.location
const head_was = ''
const body_was = ''

window.mock_location = (url = 'https://localhost') => {
  const location = new URL(url)
  location.assign = jest.fn()
  location.reload = jest.fn()
  location.replace = jest.fn()
  window_location_was = window.location
  delete window.location
  window.location = location
}

window.reset_location = () => {
  window.location = window_location_was
}

window.setup_document = (content) => {
  let element = document.createElement('html')
  element.innerHTML = content
  document.head.innerHTML = element.querySelector('head').innerHTML
  document.body.innerHTML = element.querySelector('body').innerHTML
  return content
}

window.reset_document = () => {
  document.head.innerHTML = head_was
  document.body.innerHTML = body_was
}

window.reset_head = () => {
  document.head.innerHTML = head_was
}

window.reset_body = () => {
  document.body.innerHTML = body_was
}

const dom = {
  get_asset_elements: () => {
    return dom.select_children(document.head, (e) => dom.match(e, 'script, style, link[rel=stylesheet]'))
  },
  get_provisional_elements: () => {
    return dom.select_children(document.head, (e) => !dom.match(e, 'script, style, link[rel=stylesheet]'))
  },
  select_children: (element, test) => {
    return Array.from(element.childNodes).filter(node => node.nodeType === Node.ELEMENT_NODE && test(node))
  },
  match: (element, selector) => {
    let html = document.documentElement
    let fn = html.matchesSelector || html.webkitMatchesSelector || html.msMatchesSelector || html.mozMatchesSelector
    return fn.call(element, selector)
  },
}
global.dom = dom
