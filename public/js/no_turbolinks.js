window.addEventListener('popstate', function(event) {
  if (window.Turbolinks == null && event.state.turbolinks) {
    window.location.reload()
  }
})
