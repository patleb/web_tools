const { readFileSync } = require('fs')

let cache = {}
let root = 'test/fixtures/files'
let root_was = root

const fixture = {
  json: (name, { root } = {}) => {
    return JSON.parse(fixture.read(`${name}.json`, root))
  },
  html: (name, { root } = {}) => {
    return fixture.read(`${name}.html`, root)
  },
  read: (fixture_name, fixture_path = null) => {
    const path = `${fixture_path || root}/${fixture_name}`
    if (!(path in cache)) {
      cache[path] = readFileSync(path, 'utf8')
    }
    return cache[path]
  },
  set_root: (fixture_path) => {
    root = fixture_path
  },
  reset_root: () => {
    root = root_was
  },
  reset_cache: () => {
    cache = {}
  }
}
global.fixture = fixture
