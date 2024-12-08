import concepts from '@@test/ext_coffee/concepts/spec_helper'
import '@@lib/mix_admin/all'

Js.Concepts.add_concept('Js.AdminConcept')
Js.Concepts.add_module('Js.Admin')

beforeAll(() => {
  fixture.set_root('mix_admin/test/fixtures/files/concepts')
})

module.exports = concepts
