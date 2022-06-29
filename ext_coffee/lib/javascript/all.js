var images = require.context('@@/images', true)
var image_path = function(name) { return images(name, true) }

// https://developer.mozilla.org/en-US/docs/Web/API/Page_Visibility_API
import lru from 'tiny-lru/lib/tiny-lru'

import '@@vendor/rails-ujs/all'
import '@@vendor/turbolinks/all'
import '@@lib/ext_coffee/core_ext/all'
import '@@lib/ext_coffee/rescue'
import '@@lib/ext_coffee/js/all'
import '@@lib/ext_coffee/sm/all'
import '@@lib/ext_coffee/concepts/js/all'

document.addEventListener('DOMContentLoaded', function() {
  window.$image = image_path
  window.lru = lru
})
