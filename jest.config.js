const { config } = require('shakapacker')
const { resolve } = require('path')
const jestConfigPath = resolve(config.source_path, 'lib/ext_webpacker/jest/jest.config')
const jestConfig = require(jestConfigPath)

jestConfig.roots.push('ext_coffee/test/javascript')

module.exports = jestConfig
