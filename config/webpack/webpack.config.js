const { config, merge } = require('shakapacker')
const { resolve } = require('path')
const webpackConfigPath = resolve(config.source_path, 'lib/ext_shakapacker/webpack/webpack.config')
const webpackConfig = require(webpackConfigPath)

const webpack = require('webpack')
// const { load } = require('js-yaml')
// const { readFileSync } = require('fs')
// const settings = Object.keys(load(readFileSync(resolve('config/settings.yml')), 'utf8')[process.env.NODE_ENV])

let environment = { plugins: [new webpack.EnvironmentPlugin({
  // YML_VALUE: settings.name,
})] }

module.exports = merge(webpackConfig, environment)
