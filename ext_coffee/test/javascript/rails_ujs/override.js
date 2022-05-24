dom.on_event({ element: document, 'rails:attachBindings': (event) => {
  Rails.linkClickSelector += ', a[data-custom-remote-link]'
}})
