// https://www.neontsunami.com/posts/import-whole-directory-in-webpacker
// https://gist.github.com/rossta/5a9edcd7ba37416f8c6f7ed383200b0d
import lodash from 'lodash'
import lru from 'tiny-lru/lib/tiny-lru'
import axios from 'axios'
import Chart from 'chart.js'
import 'chartjs-adapter-date-fns'
import VueLodash from 'vue-lodash'
import VueAxios from 'vue-axios'
import VueI18n from 'vue-i18n'
import Vuex from 'vuex'
import VueCookies from 'vue-cookies'
import Storage from 'vue-web-storage'
import Chartkick from 'vue-chartkick'
import { AtomSpinner } from 'epic-spinners'

Vue.use(VueLodash)
Vue.use(VueAxios, axios)
Vue.use(VueI18n)
Vue.use(Vuex)
Vue.use(VueCookies)
Vue.use(Storage, { prefix: 'app:', drivers: ['session', 'local'] })
Vue.use(Chartkick.use(Chart))
Vue.component('AtomSpinner', AtomSpinner)

document.addEventListener('DOMContentLoaded', () => {
  window.$cookies.config(true)
  window._ = lodash
  window.lru = lru
  window.$config = Vue.prototype.$config = JSON.parse(document.getElementById('js_config').getAttribute('data-config'))
  axios.defaults.headers.common['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]').getAttribute('content')

  if ($config.env === 'development') {
    _.each([Array, Boolean, Number, Object, RegExp, String], (type) => {
      type.prototype.to_json = function () { return JSON.parse(JSON.stringify(this)) }
      Object.defineProperty(type.prototype, 'to_json', { enumerable: false })
    })
  }
})
