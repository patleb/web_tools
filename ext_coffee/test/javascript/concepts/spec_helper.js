import '@@test/ext_coffee/all'
import '@@test/ext_coffee/fixtures/files/elements/banner_element'
import '@@test/ext_coffee/fixtures/files/elements/card_element'
import '@@test/ext_coffee/fixtures/files/elements/time_element'

Js.Concepts.initialize({ modules: 'Js' })

const concepts = {
  with_page: (name, before = () => {}) => {
    beforeAll(async () => {
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
