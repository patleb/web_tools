const { config } = require('@rails/webpacker')
const { resolve } = require('path')
const environment_path = resolve(config.source_path, config.source_gems_path, 'ext_webpacker/webpack/environment')
const { environment, process_env } = require(environment_path)

// const webpack = require('webpack')
// const { safeLoad } = require('js-yaml')
// const { readFileSync } = require('fs')
//
// environment.plugins.prepend('Environment', new webpack.EnvironmentPlugin(Object.assign(process_env, {
//   KEY_NAMES: Object.keys(safeLoad(readFileSync(resolve('config/locales/js.en.yml')), 'utf8').en.js.key_names),
//   GEOSERVER: true,
// })))

module.exports = environment
