const querystring = require('node:querystring')

let window_location_was = window.location

const nav = {
  mock_location: (url = 'https://localhost') => {
    const location = new URL(url)
    location.assign = jest.fn()
    location.reload = jest.fn()
    location.replace = jest.fn()
    window_location_was = window.location
    delete window.location
    window.location = location
  },
  delete_location: () => {
    delete window.location
  },
  reset_location: () => {
    window.location = window_location_was
  },
  get_anchor: (url) => {
    let match = url.match(/#(.+)$/)
    if (match) {
      return match[1]
    }
  },
  get_params: (url) => {
    url = url.replace(/^(http:\/\/localhost\/?(\w+\/?)*)?\?/, '').replace(/#(.+)$/, '')
    return JSON.parse(JSON.stringify(querystring.parse(url)))
  },
}
global.nav = nav
