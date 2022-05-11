import { readFileSync } from 'fs'

let cache = {}
let root = 'test/fixtures/files'
let root_was = root

function file_fixture(fixture_name, file_fixture_path = null) {
  const path = `${file_fixture_path || root}/${fixture_name}`
  if (!(path in cache)) {
    cache[path] = readFileSync(path, 'utf8')
  }
  return cache[path]
}

module.exports = {
  json: (name, root = null) => {
    return JSON.parse(file_fixture(`${name}.json`, root))
  },
  svg: (name, root = null) => {
    return file_fixture(`${name}.svg`, root)
  },
  html: (name, root = null) => {
    return file_fixture(`${name}.html`, root)
  },
  set_root: (file_fixture_path) => {
    root = file_fixture_path
  },
  reset_root: () => {
    root = root_was
  },
  reset_cache: () => {
    cache = {}
  }
}
