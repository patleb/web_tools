dom.on_event({ element: document, 'rails:attachBindings': (event) => {
  Rails.clickable_links += ', a[data-custom-remote-link]'
}})
