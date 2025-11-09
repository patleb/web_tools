require('@@lib/ext_coffee/jest/all')
require('@@lib/ext_coffee/jest/elements/banner_element')
require('@@lib/ext_coffee/jest/elements/card_element')
require('@@lib/ext_coffee/jest/elements/time_element')

const concepts = {
  classes: [],
  modules: ['Js'],
  with_page: (name, before = () => {}) => {
    beforeAll(async () => {
      Js.Concepts.initialize({ concepts: concepts.classes, modules: concepts.modules })
      if (before === false) {
        // do nothing
      } else if (typeof before === 'string') {
        fixture.set_root(before)
      } else {
        fixture.set_root('ext_coffee/test/fixtures/files/concepts')
        before()
      }
      concepts.load_document(name)
      await tick()
    })
    beforeEach(() => {
      concepts.enter_page(name)
    })
    afterAll(() => {
      fixture.reset_root()
      dom.reset_document()
    })
  },
  load_document: (name) => {
    if (name != null) {
      dom.setup_document(fixture.html(name))
    }
    Js.Concepts.initialize({ concepts: concepts.names, modules: concepts.modules })
    dom.fire('DOMContentLoaded')
    dom.fire('turbolinks:load', { data: { info: { once: true } } })
  },
  enter_page: (name) => {
    const document = new DOMParser().parseFromString(fixture.html(name), 'text/html')
    const body = document.body
    const event = dom.fire('turbolinks:before-render', { data: { new_body: body } })
    if (!event.defaultPrevented) {
      dom.setup_document(document)
      dom.fire('turbolinks:load', { data: { info: {} } })
    }
  },
}

module.exports = concepts
