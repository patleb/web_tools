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

// import 'core-js/stable'
// import 'regenerator-runtime/runtime'
import '@@/ext_pjax/all'

document.addEventListener('DOMContentLoaded', function () {
  window.$image = image_path

  window.$rescues = []
  window.$rescue = function (rescue) {
    var rescue_string = JSON.stringify(rescue)
    if (!_.includes($rescues, rescue_string)) {
      $rescues.push(rescue_string)
      $.ajax(Routes.path_for('rescue'), { method: 'POST', data: { rescues_javascript: rescue }})
    }
  }

  if (process.env.NODE_ENV === 'production') {
    window.addEventListener('error', function (event) {
      $rescue({
        message: event.message,
        backtrace: [_.values(_.pick(event, ['filename', 'lineno', 'colno'])).join(':')],
      })
      event.preventDefault()
      return false
    })
  }
})
