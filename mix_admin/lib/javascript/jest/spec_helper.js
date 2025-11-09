const concepts = require('@@lib/ext_coffee/jest/concepts/spec_helper')
require('@@lib/mix_admin/all')

Js.Concepts.add_concept('Js.AdminConcept')
Js.Concepts.add_module('Js.Admin')

beforeAll(() => {
  fixture.set_root('mix_admin/test/fixtures/files/concepts')
})

module.exports = concepts
