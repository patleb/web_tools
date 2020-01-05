const { environment } = require('@rails/webpacker')
const { VueLoaderPlugin } = require('vue-loader')
const vue = require('./loaders/vue')

environment.plugins.prepend('VueLoaderPlugin', new VueLoaderPlugin())
environment.loaders.prepend('vue', vue)
environment.loaders.get('sass').use.splice(-1, 0, { loader: 'resolve-url-loader' })
// environment.config.merge({
//   resolve: {
//     alias: {
//       'tiny-lru': 'tiny-lru/lib/tiny-lru'
//     }
//   }
// })
module.exports = environment
