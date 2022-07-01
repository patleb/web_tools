const defaultTheme = require('tailwindcss/defaultTheme')
const { themes, screens, ext_tailwind } = require('@@ext_tailwind/lib/javascript/tailwind/tailwind.config')

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
    screens: screens,
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
    },
  },
  plugins: [
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/forms')({ strategy: 'class' }),
    require('@tailwindcss/line-clamp'),
    require('@tailwindcss/typography'),
    require('tailwindcss-debug-screens'),
    require('daisyui'),
    ext_tailwind({ themes }),
  ],
  daisyui: {
    themes,
    logs: false
  }
}
