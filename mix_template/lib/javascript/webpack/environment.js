const fs = require('fs')
const path = require('path')
const require_module = (name) => require(path.resolve('node_modules', name))

const { environment, config } = require_module('@rails/webpacker')
const { VueLoaderPlugin } = require_module('vue-loader')
const webpack = require_module('webpack')
const erb = require('./loaders/erb')
const vue = require('./loaders/vue')
const coffee =  require('./loaders/coffee')

const source_path = path.resolve(config.source_path)
const source_gems_path = path.join(source_path, config.source_gems_path)
const global_scss_path = () => {
  let file_path = path.join(source_path, 'stylesheets', '_globals.scss')
  let exists = false; try { exists = fs.existsSync(file_path) } finally {}
  return exists ? [file_path] : []
}

switch (process.env.NODE_ENV) {
case 'development':
  environment.config.merge({ devtool: 'eval-source-map' })
  break
case 'production':
  environment.config.merge({ devtool: false })
  break
}

environment.plugins.prepend('VueLoaderPlugin', new VueLoaderPlugin())
environment.plugins.prepend('Provide', new webpack.ProvidePlugin({
  Vue:     ['vue/dist/vue.runtime.esm.js',   'default'],
  Vuex:    ['vuex/dist/vuex.esm.js',         'default'],
  VueI18n: ['vue-i18n/dist/vue-i18n.esm.js', 'default'],
}))
environment.loaders.prepend('erb', erb)
environment.loaders.prepend('vue', vue)
environment.loaders.prepend('coffee', coffee)
environment.loaders.get('sass').use.splice(-1, 0, { loader: 'resolve-url-loader' })
environment.loaders.get('sass').use.push({ loader: 'sass-resources-loader', options: { resources: global_scss_path() }})
environment.config.merge({ resolve: { alias: { '@': source_path, '@@': source_gems_path } } })
environment.resolvedModules.append('node_modules', path.resolve('node_modules'))
environment.splitChunks()

module.exports = { environment, process_env: {} }
