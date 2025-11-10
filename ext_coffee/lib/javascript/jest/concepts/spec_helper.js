require('@@lib/ext_coffee/jest/all')

const concepts = {
  root: null,
  values: {},
  before: () => {},
  classes: [],
  modules: ['Js'],
  with_page: (name, { root, values, before, classes, modules } = {}) => {
    if (root) concepts.root = root
    if (values) concepts.values = values
    if (before) concepts.before = before
    if (classes) concepts.classes = classes
    if (modules) concepts.modules = modules
    beforeAll(async () => {
      Js.Concepts.initialize({concepts: concepts.classes, modules: concepts.modules})
      if (concepts.root) {
        if (concepts.root === 'ext_coffee') concepts.root = 'ext_coffee/test/fixtures/files/concepts'
        fixture.set_root(concepts.root)
      }
      concepts.before()
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
    Js.Concepts.initialize({ concepts: concepts.names, modules: concepts.modules })
    if (name != null) {
      dom.setup_document(fixture.html(name, concepts.values))
    }
    dom.fire('DOMContentLoaded')
    dom.fire('turbolinks:load', { data: { info: { once: true } } })
  },
  enter_page: (name) => {
    const document = new DOMParser().parseFromString(fixture.html(name, concepts.values), 'text/html')
    const body = document.body
    const event = dom.fire('turbolinks:before-render', { data: { new_body: body } })
    if (!event.defaultPrevented) {
      dom.setup_document(document)
      dom.fire('turbolinks:load', { data: { info: {} } })
    }
  },
}

module.exports = concepts
