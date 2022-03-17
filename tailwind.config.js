const defaultTheme = require('tailwindcss/defaultTheme')

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
    screens: {
      ...(({ sm, md, lg, xl }) => ({ sm, md, lg, xl }))(defaultTheme.screens),
      xxl: '1536px',
    },
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
    },
  },
  plugins: [
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/forms'),
    require('@tailwindcss/line-clamp'),
    require('@tailwindcss/typography'),
    require('daisyui'),
  ],
  daisyui: {
    logs: false
  }
}
