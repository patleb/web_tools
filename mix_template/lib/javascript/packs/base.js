// https://www.neontsunami.com/posts/import-whole-directory-in-webpacker
// https://gist.github.com/rossta/5a9edcd7ba37416f8c6f7ed383200b0d
const images = require.context('@/images', true)
const image_path = (name) => images(name, true)
const consume_js_attribute = (name) => {
  const js_attribute = document.getElementById(`js_${name}`)
  if (js_attribute) {
    window[`$${name}`] = Vue.prototype[`$${name}`] = JSON.parse(js_attribute.getAttribute(`data-${name}`))
    js_attribute.remove()
  }
}

import _ from 'lodash'
import lru from 'tiny-lru/lib/tiny-lru'
import axios from 'axios'
import Chart from 'chart.js'
import 'chartjs-adapter-date-fns'
import VueLodash from 'vue-lodash'
import VueAxios from 'vue-axios'
import VueCookies from 'vue-cookies'
import Storage from 'vue-web-storage'
import Chartkick from 'vue-chartkick'
import { AtomSpinner } from 'epic-spinners'

Vue.use(Vuex)
Vue.use(VueI18n)
Vue.use(VueLodash)
Vue.use(VueAxios, axios)
Vue.use(VueCookies)
Vue.use(Storage, { prefix: 'app:', drivers: ['session', 'local'] })
Vue.use(Chartkick.use(Chart))
Vue.component('AtomSpinner', AtomSpinner)

document.addEventListener('DOMContentLoaded', () => {
  window.$cookies.config(true)
  window._ = _
  window.lru = lru
  window.$image = image_path
  consume_js_attribute('config')
  consume_js_attribute('locales')
  axios.defaults.headers.common['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]').getAttribute('content')

  window.$rescues = []
  window.addEventListener('error', function (event) {
    let rescue = {
      message: event.message,
      backtrace: [_.values(_.pick(event, ['filename', 'lineno', 'colno'])).join(':')],
      data: {}
    }
    let rescue_string = JSON.stringify(rescue)
    if (!_.includes($rescues, rescue_string)) {
      $rescues.push(rescue_string)
      axios.post(`${$config.url}/javascript_rescues`, { javascript_rescue: rescue }).catch(() => {})
    }
    event.preventDefault()
    return false
  })

  Vue.config.errorHandler = (error, vm, info) => {
    let rescue = {
      message: `${info}: ${error}`,
      backtrace: error.stack || [],
      data: { tag: vm.$el.localName, id: vm.$el.id, class: vm.$el.className }
    }
    let rescue_string = JSON.stringify(rescue)
    if (!_.includes($rescues, rescue_string)) {
      $rescues.push(rescue_string)
      axios.post(`${$config.url}/javascript_rescues`, { javascript_rescue: rescue }).catch(() => {})
    }
    return false
  }

  _.each([Array, Boolean, Number, Object, RegExp, String], (type) => {
    type.prototype.to_json = function () { return JSON.parse(JSON.stringify(this)) }
    Object.defineProperty(type.prototype, 'to_json', { enumerable: false })
  })
})
