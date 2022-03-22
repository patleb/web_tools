module.exports = {
  plugins: [
    require('tailwindcss')('./tmp/tailwind.config.js'),
    require('tailwindcss/nesting'),
    require('autoprefixer'),
    require('postcss-flexbugs-fixes'),
    require('postcss-preset-env')({
      autoprefixer: {
        flexbox: 'no-2009'
      },
      features: {
        'nesting-rules': false
      },
      stage: 3
    })
  ]
}
