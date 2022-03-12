const path = require('path')
const require_module = (name) => require(path.resolve('node_modules', name))

const { webpackConfig, config, merge } = require_module('shakapacker')
const webpack = require_module('webpack')
const source_path = path.resolve(config.source_path)
const source_gems_path = path.join(source_path, config.source_gems_path)

let base = webpackConfig
switch (process.env.NODE_ENV) {
case 'development':
  base = merge(base, { devtool: 'eval-source-map' })
  break
case 'production':
  base = merge(base, { devtool: false })
  break
}
base = merge(base, { plugins: [new webpack.ProvidePlugin({
  $:      'jquery',
  jQuery: 'jquery',
})]})
base = merge(base, { resolve: { alias: { '@': source_path, '@@': source_gems_path } } })
base = merge(base, { resolve: { modules: [path.resolve('node_modules')] } })
base = merge(base, { resolve: { extensions: ['.css', '.scss'] } })

module.exports = { webpackConfig: base, process_env: {} }
