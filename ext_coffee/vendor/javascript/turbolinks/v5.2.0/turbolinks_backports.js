// app/javascript/application.js
// -----------------------------
// import Rails from '@@vendor/rails-ujs/v5.2.8/rails-ujs.min.js'
// import Turbolinks from '@@vendor/turbolinks/v5.2.0/turbolinks.min.js'
// import '@@vendor/turbolinks/v5.2.0/turbolinks_backports'
//
// Rails.start()
// Turbolinks.start()
//
// document.addEventListener('DOMContentLoaded', function() {
//   window.Rails = Rails
//   window.Turbolinks = Turbolinks
//   Turbolinks.dispatch('turbolinks:backports')
// })

// Search forms
document.addEventListener('turbolinks:backports', function() {
  Rails.delegate(document, 'form[method=get]:not([data-remote=true])', 'submit', function(event) {
    if (Turbolinks.controller.nodeIsVisitable(document.activeElement)) {
      var url = this.action
      var anchor = url.split('#')[1]
      if (anchor != null) {
        url = url.replace('#' + anchor, '')
      }
      var params = Rails.serializeElement(this, document.activeElement)
      if (url.indexOf('?') === -1) {
        url = url + '?' + params
      } else {
        url = url + '&' + params
      }
      if (anchor != null) {
        url = url + '#' + anchor
      }
      Turbolinks.visit(url)
      return false
    }
  })
})

// Prevent server call on same page anchor links and allow page reloads
document.addEventListener('turbolinks:click', function (event) {
  switch (event.target.getAttribute('href').charAt(0)) {
  case '#':
    event.preventDefault()
    if (event.target.href !== location.href) {
      Turbolinks.controller.pushHistoryWithLocationAndRestorationIdentifier(event.data.url, Turbolinks.uuid())
      Turbolinks.controller.cacheSnapshot()
    }
    break
  case '?':
    event.preventDefault()
    break
  }
})

// Redirects with CSP enabled
document.addEventListener('turbolinks:request-start', function(event) {
  var nonce = Rails.cspNonce()
  if (nonce) {
    event.data.xhr.setRequestHeader('X-Turbolinks-Nonce', nonce)
  }
})
document.addEventListener('turbolinks:before-cache', function() {
  var nonces = document.querySelectorAll('script[nonce]')
  for (var i = 0; i < nonces.length; i++) {
    var element = nonces[i]
    if (element.nonce) {
      element.setAttribute('nonce', element.nonce)
    }
  }
})

// Prevent repeated autoplay
var autoplay_ids = []
document.addEventListener('turbolinks:before-cache', function () {
  var autoplays = document.querySelectorAll('[autoplay]')
  for (var i = 0; i < autoplays.length; i++) {
    if (!autoplays[i].id) {
      throw 'autoplay elements need an ID attribute'
    }
    autoplay_ids.push(autoplays[i].id)
    autoplays[i].removeAttribute('autoplay')
  }
})
document.addEventListener('turbolinks:before-render', function (event) {
  var ids = []
  for (var i = 0; i < autoplay_ids.length; i++) {
    var autoplay = event.data.newBody.querySelector('#' + autoplay_ids[i])
    if (autoplay) {
      autoplay.setAttribute('autoplay', 'true')
    } else {
      ids.push(autoplay_ids[i])
    }
  }
  autoplay_ids = ids
})
