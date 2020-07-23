import _ from 'lodash'
import NProgress from 'accessible-nprogress'
import Cookies from 'js-cookie'
import jstz from 'jstz'
import moment from 'moment'
import 'jquery'
import 'jquery.iframe-transport'
import 'jquery-touch-events'
import 'eonasdan-bootstrap-datetimepicker'

import '@@/ext_pjax/moment/locales'
import '@@/ext_pjax/jquery_ui/slim'
import '@@/ext_pjax/env'
import '@@/ext_pjax/logger'
import '@@/ext_pjax/core_ext'
import '@@/ext_pjax/core_ext/all'
import '@@/ext_pjax/state_machine'
import '@@/ext_pjax/pjax'
import '@@/ext_pjax/cookie'
import '@@/ext_pjax/concepts'
import '@@/ext_pjax/concepts/all'

# TODO maybe just lodash?
# https://bibwild.wordpress.com/2019/08/01/dealing-with-legacy-and-externally-loaded-code-in-webpacker/
# https://stackoverflow.com/questions/51920575/how-to-make-jquery-available-to-sprockets-using-webpacker
document.addEventListener 'DOMContentLoaded', =>
  window._ = _
  window.NProgress = NProgress
  window.Cookies = Cookies
  window.jstz = jstz
  window.moment = moment
