const { config } = require('shakapacker')
const { resolve } = require('path')
const jestConfigPath = resolve(config.source_path, 'lib/ext_webpacker/jest/jest.config')
const jestConfig = require(jestConfigPath)

jestConfig.roots.push('ext_coffee/test/javascript')
jestConfig.moduleNameMapper = {
  '^@@lib/ext_coffee/(.+)': '<rootDir>/ext_coffee/lib/javascript/$1',
  '^@@lib/ext_webpacker/(.+)': '<rootDir>/ext_webpacker/lib/javascript/$1',
  '^@@test/ext_coffee/fixtures/(.+)': '<rootDir>/ext_coffee/test/fixtures/$1',
  '^@@test/ext_coffee/(.+)': '<rootDir>/ext_coffee/test/javascript/$1',
  '^@@vendor/rails-ujs/(.+)': '<rootDir>/ext_coffee/vendor/javascript/rails-ujs/$1',
  '^@@vendor/turbolinks/(.+)': '<rootDir>/ext_coffee/vendor/javascript/turbolinks/$1',
}

module.exports = jestConfig
