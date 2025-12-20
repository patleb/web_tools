import icons from "bootstrap-icons/font/bootstrap-icons.json";
import '@@lib/ext_css/index'

document.addEventListener('DOMContentLoaded', function() {
  Object.keys(icons).forEach(name => { icons[name] = String.fromCodePoint(icons[name]) })
  window.ICONS = icons
  document.documentElement.classList.remove('no-js')
  document.cookie = '_js=yes; path=/' + ((window.location.protocol === 'https:') ? '; secure' : '')
})

if (window.Turbolinks) {
  Rails.document_on('turbolinks:before-render', function () {
    clearTimeout(window.no_transition_timeout)
  })

  Rails.document_on('turbolinks:load', function () {
    window.no_transition_timeout = setTimeout(function () {
      document.documentElement.classList.remove('no-transition')
    }, 250)
  })
}
