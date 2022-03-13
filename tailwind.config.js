// TODO
// yarn add @fontsource/inter
// https://github.com/rails/tailwindcss-rails
// const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    "@/app/helpers/**/*.rb",
    "@/app/javascript/**/*.{js,coffee}",
    "@/app/presenters/**/*.rb",
    "@/app/views/**/*.html.{erb,ruby}",
    "@@/ext_tailwind/app/helpers/**/*.rb",
  ],
  theme: {
    extend: {
      // fontFamily: {
      //   sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      // },
    },
  },
  plugins: [
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/forms'),
    require('@tailwindcss/line-clamp'),
    require('@tailwindcss/typography'),
    require('daisyui'),
  ],
}
