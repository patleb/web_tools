const { config } = require('shakapacker')
const { resolve } = require('path')
const jestConfigPath = resolve(config.source_path, 'lib/ext_shakapacker/jest/jest.config')
const jestConfig = require(jestConfigPath)

jestConfig.roots.push(
  'ext_coffee/test/javascript',
  'mix_admin/test/javascript',
)
jestConfig.moduleNameMapper = {
  '^@@test/ext_coffee/fixtures/(.+)': '<rootDir>/ext_coffee/test/fixtures/$1',
  '^@@test/ext_coffee/(.+)':          '<rootDir>/ext_coffee/test/javascript/$1',
  ...jestConfig.moduleNameMapper
}

module.exports = jestConfig
