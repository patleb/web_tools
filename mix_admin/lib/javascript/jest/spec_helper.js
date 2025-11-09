const concepts = require('@@lib/ext_coffee/jest/concepts/spec_helper')
require('@@lib/mix_admin/all')

beforeAll(() => {
  fixture.set_root('mix_admin/test/fixtures/files/concepts')
})

module.exports = concepts
