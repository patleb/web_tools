import $ from 'jquery'
import _ from 'lodash'
import lru from 'tiny-lru/lib/tiny-lru'
import Hamster from 'hamsterjs'
import NProgress from 'accessible-nprogress'
import Cookies from 'js-cookie'
import jstz from 'jstz'
import 'jquery.iframe-transport'
import 'jquery-touch-events'
// import { AtomSpinner } from 'epic-spinners'

import '@@lib/ext_pjax/env.coffee.erb'
import '@@lib/ext_pjax/logger'
import '@@lib/ext_pjax/core_ext'
import '@@lib/ext_pjax/core_ext/all'
import '@@lib/ext_pjax/state_machine'
import '@@lib/ext_pjax/pjax'
import '@@lib/ext_pjax/cookie'
import '@@lib/ext_pjax/concepts'
import '@@lib/ext_pjax/concepts/all'

document.addEventListener('DOMContentLoaded', () => {
  window.$image = image_path
  window.$ = window.jQuery = $
  window._ = _
  window.lru = lru
  window.Hamster = Hamster
  window.NProgress = NProgress
  window.Cookies = Cookies
  window.jstz = jstz
})
