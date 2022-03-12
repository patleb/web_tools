const { config } = require('shakapacker')
const { resolve } = require('path')
const base_path = resolve(config.source_path, config.source_gems_path, 'ext_webpacker/webpack/base')
const { webpackConfig, process_env } = require(base_path)

// const webpack = require('webpack')
// const { safeLoad } = require('js-yaml')
// const { readFileSync } = require('fs')
//
// webpackConfig.plugins.prepend('Environment', new webpack.EnvironmentPlugin(Object.assign(process_env, {
//   YML_VALUE: Object.keys(safeLoad(readFileSync(resolve('config/settings.yml')), 'utf8')[process.env.NODE_ENV].name),
//   STATIC_VALUE: true,
// })))

module.exports = webpackConfig
