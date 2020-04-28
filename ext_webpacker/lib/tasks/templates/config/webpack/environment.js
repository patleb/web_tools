const { config } = require('@rails/webpacker')
const { resolve } = require('path')
const environment = require(resolve(config.source_path, config.source_gems_path, 'mix_template/webpack/environment'))

module.exports = environment
