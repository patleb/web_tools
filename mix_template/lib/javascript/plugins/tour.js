import Tour from '@@/mix_template/components/tour'
import TourStep from '@@/mix_template/components/tour/step'

// Declare install function executed by Vue.use()
export function install(Vue) {
  if (install.installed) {
    return
  }
  install.installed = true
  Vue.component('Tour', Tour)
  Vue.component('TourStep', TourStep)
  Vue.prototype.$tours = {}
}

// Create module definition for Vue.use()
const plugin = {
  install,
}

// Auto-install when vue is found (eg. in browser via <script> tag)
let GlobalVue = null
if (typeof window !== 'undefined') {
  GlobalVue = window.Vue
} else if (typeof global !== 'undefined') {
  GlobalVue = global.Vue
}
if (GlobalVue) {
  GlobalVue.use(plugin)
}

// To allow use as module (npm/webpack/etc.) export component
// export default Tour

export default plugin
