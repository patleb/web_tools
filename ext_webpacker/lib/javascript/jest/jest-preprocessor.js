const coffee = require('coffeescript')

module.exports = {
  process: (src, path) => {
    if (coffee.helpers.isCoffee(path)) {
      return { code: coffee.compile(src, { bare: true, filename: path, inlineMap: true }) }
    }
    return src
  }
}
