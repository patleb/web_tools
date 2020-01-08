process.env.NODE_ENV = process.env.NODE_ENV || 'vagrant'

const environment = require('./environment')

module.exports = environment.toWebpackConfig()
