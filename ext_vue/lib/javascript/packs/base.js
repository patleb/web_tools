/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb


// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
const images = require.context('@/images', true)
const image_path = (name) => images(name, true)

// https://www.neontsunami.com/posts/import-whole-directory-in-webpacker
// https://gist.github.com/rossta/5a9edcd7ba37416f8c6f7ed383200b0d
const consume_js_attribute = (name) => {
  const js_attribute = document.getElementById(`js_${name}`)
  if (js_attribute) {
    window[`$${name}`] = Vue.prototype[`$${name}`] = JSON.parse(js_attribute.getAttribute(`data-${name}`))
    js_attribute.remove()
  }
}

import 'core-js/stable'
import 'regenerator-runtime/runtime'
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
import * as uiv from 'uiv'
import { AtomSpinner } from 'epic-spinners'

Vue.use(Vuex)
Vue.use(VueI18n)
Vue.use(VueLodash)
Vue.use(VueAxios, axios)
Vue.use(VueCookies)
Vue.use(Storage, { prefix: 'js.', drivers: ['session', 'local'] })
Vue.use(Chartkick.use(Chart))
Vue.use(uiv)
Vue.component('AtomSpinner', AtomSpinner)

document.addEventListener('DOMContentLoaded', () => {
  let session = true
  let secure = (window.location.protocol === 'https:')
  window.$cookies.config(session, null, null, secure)
  window._ = _
  window.lru = lru
  window.$image = image_path
  consume_js_attribute('config')
  consume_js_attribute('locales')
  consume_js_attribute('routes')
  axios.defaults.headers.common['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]').content

  window.$rescues = []
  window.$rescue = function (http, rescue) {
    let rescue_string = JSON.stringify(rescue)
    if (!_.includes($rescues, rescue_string)) {
      $rescues.push(rescue_string)
      http.post($routes.rescue, { rescues_javascript: rescue }).catch(() => {})
    }
  }

  if (process.env.NODE_ENV === 'production') {
    window.addEventListener('error', function (event) {
      $rescue(axios, {
        message: event.message,
        backtrace: [_.values(_.pick(event, ['filename', 'lineno', 'colno'])).join(':')],
        data: {}
      })
      event.preventDefault()
      return false
    })
  }

  if (process.env.NODE_ENV === 'production') {
    Vue.config.errorHandler = (error, vm, info) => {
      $rescue(axios, {
        message: `${info}: ${error}`,
        backtrace: error.stack || [],
        data: {tag: vm.$el.localName, id: vm.$el.id, class: vm.$el.className}
      })
      return false
    }
  }

  _.each([Array, Boolean, Number, Object, RegExp, String], (type) => {
    type.prototype.to_json = function () { return JSON.parse(JSON.stringify(this)) }
    Object.defineProperty(type.prototype, 'to_json', { enumerable: false })
  })
})
