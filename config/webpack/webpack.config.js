const { config } = require('shakapacker')
const { resolve } = require('path')
const webpackConfigPath = resolve(config.source_path, config.source_gems_path, 'ext_webpacker/webpack/webpack.config')
const webpackConfig = require(webpackConfigPath)

// const webpack = require('webpack')
// const { safeLoad } = require('js-yaml')
// const { readFileSync } = require('fs')
//
// let environment = { plugins: [new webpack.EnvironmentPlugin(Object.assign(process.env, {
//   YML_VALUE: Object.keys(safeLoad(readFileSync(resolve('config/settings.yml')), 'utf8')[process.env.NODE_ENV].name),
//   STATIC_VALUE: 'name',
// }))] }
// module.exports = merge(webpackConfig, environment)

module.exports = webpackConfig
