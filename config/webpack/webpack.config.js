const { config } = require('shakapacker')
const { resolve } = require('path')
const webpackConfigPath = resolve(config.source_path, 'lib/ext_webpacker/webpack/webpack.config')
const webpackConfig = require(webpackConfigPath)

// const webpack = require('webpack')
// const { safeLoad } = require('js-yaml')
// const { readFileSync } = require('fs')
// const settings = Object.keys(safeLoad(readFileSync(resolve('config/settings.yml')), 'utf8')[process.env.NODE_ENV])

// let environment = { plugins: [new webpack.EnvironmentPlugin(Object.assign(process.env, {
//   YML_VALUE: settings.name,
//   LOGGER_DEBUG: true
//   LOGGER_TRACE: true
// }))] }
// module.exports = merge(webpackConfig, environment)

module.exports = webpackConfig
