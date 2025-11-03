const path = require('path')
const require_module = (name) => require(path.resolve('node_modules', name))

const { generateWebpackConfig, config, merge } = require_module('shakapacker')
const webpack = require_module('webpack')
const node_modules = path.resolve('node_modules')
const source = path.resolve(config.source_path)
const source_lib = path.join(source, 'lib')
const source_vendor = path.join(source, 'vendor')
const { existsSync } = require('fs')

let devtool = config.devtool != null ? { devtool: config.devtool } : {}
let screens = false
try {
  const tailwindConfigPath = path.resolve('./tmp/tailwind.config.js')
  if (existsSync(tailwindConfigPath)) {
    const resolveConfig = require('tailwindcss/resolveConfig')
    const tailwindConfig = require(tailwindConfigPath)
    const fullConfig = resolveConfig(tailwindConfig)
    screens = fullConfig.theme.screens
  }
} catch(err) {
  // do nothing
}
let environment = { plugins: [new webpack.EnvironmentPlugin({
  SCREENS: JSON.stringify(screens),
})] }

module.exports = merge(generateWebpackConfig(), devtool, environment, {
  resolve: {
    alias: { '@@': source, '@@lib': source_lib, '@@vendor': source_vendor, '@@node_modules': node_modules },
    modules: [node_modules],
    extensions: ['.css', '.scss'],
    symlinks: false,
  },
  // plugins: [new webpack.ProvidePlugin({
  //   _: 'underscore',
  // })]
})
