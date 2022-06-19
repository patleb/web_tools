import '@@vendor/rails-ujs/all'
import '@@lib/ext_coffee/core_ext/all'
import '@@lib/ext_coffee/js/all'
import '@@lib/ext_coffee/concepts/js/all'

Js.Concepts.initialize({ modules: 'Js' })

const load_page = (name) => {
  dom.setup_document(fixture.html(name, { root: 'ext_coffee/test/fixtures/files/concepts/js' }))
}

const concepts = {
  with_page: (name) => {
    beforeAll(async () => {
      concepts.load_document(name)
      await tick()
    })
    beforeEach(() => {
      concepts.exit_page()
      concepts.enter_page(name)
    })
    afterAll(() => {
      concepts.exit_page()
    })
  },
  load_document: (name) => {
    if (name != null) {
      load_page(name)
    }
    dom.fire('DOMContentLoaded')
    dom.fire('turbolinks:load', { data: { info: { once: true } } })
  },
  enter_page: (name) => {
    load_page(name)
    dom.fire('turbolinks:load', { data: { info: {} } })
  },
  exit_page: () => {
    dom.fire('turbolinks:before-render')
    dom.reset_document()
  }
}

module.exports = concepts
