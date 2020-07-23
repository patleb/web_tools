import _ from 'lodash'
import $ from 'jquery'
import NProgress from 'accessible-nprogress'
import Cookies from 'js-cookie'
import jstz from 'jstz'
import moment from 'moment'
import 'jquery.iframe-transport'
import 'jquery-touch-events'
import 'eonasdan-bootstrap-datetimepicker'

import '@@/ext_bootstrap/all'
import '@@/ext_pjax/moment/locales.js.erb'
import '@@/ext_pjax/jquery_ui/slim'
import '@@/ext_pjax/env.coffee.erb'
import '@@/ext_pjax/logger'
import '@@/ext_pjax/core_ext'
import '@@/ext_pjax/core_ext/all'
import '@@/ext_pjax/state_machine'
import '@@/ext_pjax/pjax'
import '@@/ext_pjax/cookie'
import '@@/ext_pjax/concepts'
import '@@/ext_pjax/concepts/all'

document.addEventListener('DOMContentLoaded', function () {
  window._ = _
  window.$ = window.jQuery = $
  window.NProgress = NProgress
  window.Cookies = Cookies
  window.jstz = jstz
  window.moment = moment
})
