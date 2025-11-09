const { config } = require('shakapacker')
const { resolve } = require('path')
const jestConfigPath = resolve(config.source_path, 'lib/ext_shakapacker/jest/jest.config')
const jestConfig = require(jestConfigPath)

jestConfig.roots.push(
  'ext_coffee/test/javascript',
  'mix_admin/test/javascript',
)

module.exports = jestConfig
