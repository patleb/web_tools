import '@@vendor/rails-ujs/all'
import '@@lib/ext_coffee/core_ext/all'
import '@@lib/ext_coffee/js/all'
import '@@lib/ext_coffee/concepts/js/all'

Js.Concepts.initialize({ modules: 'Js' })

const load_page = () => {
  dom.setup_document(fixture.html('storage', { root: 'ext_coffee/test/fixtures/files/concepts/js' }))
}

const concepts = {
  load_document: (name) => {
    load_page(name)
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

