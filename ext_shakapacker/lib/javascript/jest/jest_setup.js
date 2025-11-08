require('@@lib/ext_shakapacker/jest/helpers/assert')
require('@@lib/ext_shakapacker/jest/helpers/dom')
require('@@lib/ext_shakapacker/jest/helpers/fixture')
require('@@lib/ext_shakapacker/jest/helpers/nav')

global.xhr = require('xhr-mock/dist/xhr-mock')
global.jest_console = global.console
global.console = require('console')
global.tick = async (n = 1) => {
  while (n--) {
    await delay(1000 / 60)
  }
}
global.delay = (ms = 1) => new Promise(resolve => setTimeout(resolve, ms))

if (process.env.JB_PUBLISH_PORT != null) {
  jest.setTimeout(2147483647)
}

Object.assign(process.env, {
  SCREENS: null,
})
