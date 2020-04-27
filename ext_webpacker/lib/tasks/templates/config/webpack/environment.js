const { config } = require('@rails/webpacker')
const path = require('path')
const source_path = path.resolve(config.source_path)
const source_gems_path = path.join(source_path, config.source_gems_path)
const environment = require(path.join(source_gems_path, 'mix_template/webpack/environment'))

module.exports = environment
