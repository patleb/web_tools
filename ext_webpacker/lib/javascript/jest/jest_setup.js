import '@@lib/ext_webpacker/jest/helpers/assert'
import '@@lib/ext_webpacker/jest/helpers/dom'
import '@@lib/ext_webpacker/jest/helpers/fixture'
import '@@lib/ext_webpacker/jest/helpers/nav'
import xhr from 'xhr-mock'

global.xhr = xhr
global.tick = async (n = 1) => {
  while (n--) {
    await delay(1000 / 60)
  }
}
global.delay = (ms = 1) => new Promise(resolve => setTimeout(resolve, ms))

if (process.env.JB_PUBLISH_PORT != null) {
  jest.setTimeout(2147483647)
}

global.jest_console = global.console
global.console = require('console')

Object.assign(process.env, {
  SCREENS: null,
  LOGGER_DEBUG: false,
  LOGGER_TRACE: false,
})
