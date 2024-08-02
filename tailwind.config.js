const defaultTheme = require('tailwindcss/defaultTheme')
const { themes, screens, ext_css } = require('@@ext_css/lib/javascript/tailwind/tailwind.config')
/* const { gem_name } = require('@@gem_name/lib/javascript/tailwind/tailwind.config')
 * // plugin code in tailwind.config
 * const plugin = require('tailwindcss/plugin')
 * const gem_name = plugin(({ ... }) => {
 *   ...
 * })
 * ...
 * module.exports = {
 *   gem_name,
 * }
 */

let plugins = [
  require('@tailwindcss/aspect-ratio'),
  require('@tailwindcss/container-queries'),
  require('@tailwindcss/forms')({ strategy: 'class' }),
  require('@tailwindcss/line-clamp'),
  require('@tailwindcss/typography'),
  require('daisyui'),
  ext_css({ themes }),
  // gem_name,
]
if (process.env.NODE_ENV !== 'production') {
  plugins.push(require('tailwindcss-debug-screens'))
}

module.exports = {
  content: {
    files: [
      "@@/app/helpers/**/*.rb",
      "@@/app/javascript/**/*.{js,coffee}",
      "@@/app/presenters/**/*.rb",
      "@@/app/views/**/*.html.{erb,ruby}",
      "Webpacker::TAILWIND_DEPENDENCIES",
    ],
    extract: {
      DEFAULT: 'Webpacker::TAILWIND_EXTRACTOR',
    }
  },
  theme: {
    screens,
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
    },
  },
  corePlugins: {
    aspectRatio: false,
  },
  plugins,
  daisyui: {
    themes,
    logs: false
  }
}
