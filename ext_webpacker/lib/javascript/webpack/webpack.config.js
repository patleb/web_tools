const path = require('path')
const require_module = (name) => require(path.resolve('node_modules', name))

const { webpackConfig, config, merge } = require_module('shakapacker')
const webpack = require_module('webpack')
const source_path = path.resolve(config.source_path)
const source_lib_path = path.join(source_path, 'lib')
const source_vendor_path = path.join(source_path, 'vendor')
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
screens = { plugins: [new webpack.EnvironmentPlugin(Object.assign(process.env, {
  SCREENS: JSON.stringify(screens)
}))] }

module.exports = merge(webpackConfig, devtool, screens, {
  resolve: {
    alias: { '@@': source_path, '@@lib': source_lib_path, '@@vendor': source_vendor_path },
    modules: [path.resolve('node_modules')],
    extensions: ['.css', '.scss'],
  },
  plugins: [new webpack.ProvidePlugin({
    $:      'jquery',
    jQuery: 'jquery',
  })]
})
