import '@@lib/ext_webpacker/jest/helpers/assert'
import '@@lib/ext_webpacker/jest/helpers/dom'
import '@@lib/ext_webpacker/jest/helpers/fixture'
import '@@lib/ext_webpacker/jest/helpers/url'
import * as matchers from 'jest-extended'
import xhr from 'xhr-mock'

global.xhr = xhr
expect.extend(matchers)

if (process.env.JB_PUBLISH_PORT != null) {
  jest.setTimeout(2147483647)
}
