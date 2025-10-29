var images = require.context('@@/images', true)
var image_path = function(name) { return images(name, true) }

// https://developer.mozilla.org/en-US/docs/Web/API/Page_Visibility_API
import { lru } from 'tiny-lru'
import Cookies from 'js-cookie'
import { enableDragDropTouch } from 'drag-drop-touch'
import sortable from 'html5sortable/dist/html5sortable.es'

import '@@lib/ext_coffee/core_ext/all'
import '@@lib/ext_coffee/index'
import '@@lib/ext_coffee/concepts'
import '@@lib/ext_coffee/state_machine'
import '@@lib/ext_coffee/concepts/all'
import '@@lib/ext_coffee/elements/all'
import '@@lib/ext_coffee/state_machines/all'
import '@@vendor/turbolinks/all'
import Hamster from '@@vendor/hamsterjs/hamster'

document.addEventListener('DOMContentLoaded', function() {
  window.$image = image_path
  window.lru = lru
  window.Cookies = Cookies
  window.sortable = sortable
  window.Hamster = Hamster
  enableDragDropTouch()
})
