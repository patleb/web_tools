const images = require.context('@@/images', true)
const image_path = (name) => images(name, true)

import $ from 'jquery'
import _ from 'lodash'
import lru from 'tiny-lru/lib/tiny-lru'
import Cookies from 'js-cookie'
import jstz from 'jstz'
import 'jquery-touch-events'

import Hamster from '@@vendor/hamsterjs/hamster'
import '@@vendor/jquery-iframe-transport/jquery.iframe-transport'

import '@@lib/ext_pjax/env.coffee.erb'
import '@@lib/ext_pjax/logger'
import '@@lib/ext_pjax/core_ext'
import '@@lib/ext_pjax/core_ext/all'
import '@@lib/ext_pjax/state_machine'
import '@@lib/ext_pjax/state_machine/all'
import '@@lib/ext_pjax/pjax'
import '@@lib/ext_pjax/cookie'
import '@@lib/ext_pjax/concepts'
import '@@lib/ext_pjax/concepts/all'

document.addEventListener('DOMContentLoaded', () => {
  window.$image = image_path
  window.$ = window.jQuery = $
  window._ = _
  window.lru = lru
  window.Cookies = Cookies
  window.jstz = jstz
  window.Hamster = Hamster
})
