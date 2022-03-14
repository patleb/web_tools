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

import '@@/ext_pjax/env.coffee.erb'
import '@@/ext_pjax/logger'
import '@@/ext_pjax/core_ext'
import '@@/ext_pjax/core_ext/all'
import '@@/ext_pjax/state_machine'
import '@@/ext_pjax/pjax'
import '@@/ext_pjax/cookie'
import '@@/ext_pjax/concepts'
import '@@/ext_pjax/concepts/all'

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
