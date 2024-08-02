import '@@vendor/rails-ujs/all'
import '@@lib/ext_coffee/core_ext/all'
import '@@lib/ext_coffee/js/all'
import '@@lib/ext_coffee/concepts/all'
import '@@test/ext_coffee/fixtures/files/concepts/js/component/banner_element'
import '@@test/ext_coffee/fixtures/files/concepts/js/component/card_element'
import '@@test/ext_coffee/fixtures/files/concepts/js/component/time_element'

Js.Concepts.initialize({ modules: 'Js' })

const concepts = {
  with_page: (name, before = () => {}) => {
    beforeAll(async () => {
      fixture.set_root('ext_coffee/test/fixtures/files/concepts/js')
      before()
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
