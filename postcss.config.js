module.exports = {
  parser: require('postcss-comment'),
  plugins: [
    require('tailwindcss/nesting'),
    require('tailwindcss')('./tmp/tailwind.config.js'),
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
