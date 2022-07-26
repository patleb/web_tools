const defaultTheme = require('tailwindcss/defaultTheme')
const { themes, screens, ext_sass } = require('@@ext_sass/lib/javascript/tailwind/tailwind.config')

let plugins = [
  require('@tailwindcss/aspect-ratio'),
  require('@tailwindcss/forms')({ strategy: 'class' }),
  require('@tailwindcss/line-clamp'),
  require('@tailwindcss/typography'),
  require('daisyui'),
  ext_sass({ themes }),
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
      "ExtWebpacker::Gems::TAILWIND_DEPENDENCIES",
    ],
    extract: {
      DEFAULT: 'ExtWebpacker::Gems::TAILWIND_EXTRACTOR',
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
  plugins,
  daisyui: {
    themes,
    logs: false
  }
}
