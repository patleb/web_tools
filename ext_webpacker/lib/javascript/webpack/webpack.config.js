const path = require('path')
const require_module = (name) => require(path.resolve('node_modules', name))

const { webpackConfig, config, merge } = require_module('shakapacker')
const webpack = require_module('webpack')
const source_path = path.resolve(config.source_path)
const source_gems_path = path.join(source_path, config.source_gems_path)

let devtool = {}
switch (process.env.NODE_ENV) {
case 'development':
  devtool = { devtool: 'eval-source-map' }
  break
case 'production':
  devtool = { devtool: false }
  break
}

module.exports = merge(webpackConfig, devtool, {
  resolve: {
    alias: { '@': source_path, '@@': source_gems_path },
    modules: [path.resolve('node_modules')],
    extensions: ['.css', '.scss'],
  },
  plugins: [new webpack.ProvidePlugin({
    $:      'jquery',
    jQuery: 'jquery',
  })]
})
