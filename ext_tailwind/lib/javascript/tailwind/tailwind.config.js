// TODO make it classless like https://github.com/stackhackerio/classless
// node_modules/tailwindcss/stubs/defaultConfig.stub.js
const defaultTheme = require('tailwindcss/defaultTheme')
const daisyui_themes = require('daisyui/src/colors/themes')
const theme_options = {
  "--rounded-box": "0",
  "--rounded-btn": "0",
  "--rounded-badge": "0",
  "--tab-radius": "0",
  "--btn-focus-scale": "0.8",
}
const themes = [{
  light: {
    ...daisyui_themes["[data-theme=light]"],
    ...theme_options,
  }},{
  dark: {
    ...daisyui_themes["[data-theme=dark]"],
    ...theme_options,
}}]
const screens = {
  'sm-1': { max: `${parseInt(defaultTheme.screens.sm) - 1}px` }, // mini < 640
  'md-1': { max: `${parseInt(defaultTheme.screens.md) - 1}px` }, // phone < 768
  'lg-1': { max: `${parseInt(defaultTheme.screens.lg) - 1}px` }, // tablet < 1024
  'xl-1': { max: `${parseInt(defaultTheme.screens.xl) - 1}px` }, // laptop < 1280
  '2xl-1': { max: `${parseInt(defaultTheme.screens['2xl']) - 1}px` }, // desktop < 1536
  xs: '320px',
  ...defaultTheme.screens,
}
const plugin = require('tailwindcss/plugin')
const ext_tailwind = ({ themes = true, darkTheme = 'dark' } = {}) => {
  if (themes === false) {
    themes = ['light']
  }
  const colors = {}
  themes.forEach((theme, i) => {
    let theme_name = theme
    let theme_key
    if (theme === Object(theme)) {
      theme_name = Object.keys(theme)[0]
      theme_key = `[data-theme=${theme_name}]`
    } else {
      theme_key = `[data-theme=${theme}]`
      theme = daisyui_themes[theme_key]
    }
    const theme_colors = theme[theme_name]
    Object.entries(theme_colors).forEach(([color, value]) => {
      // https://stackoverflow.com/questions/55329996/how-to-create-color-shades-using-css-variables-similar-to-darken-of-sass
      if (!color.startsWith('--')) {
        if (i === 0) {
          colors[':root'] = colors[':root'] || {}
          colors[':root'][`--${color}`] = value
        }
        colors[theme_key] = colors[theme_key] || {}
        colors[theme_key][`--${color}`] = value
      }
    })
  })
  return plugin(({ addBase }) => {
    addBase(colors);
    // addComponent?
  })
}

module.exports = {
  themes,
  screens,
  ext_tailwind,
}
// TODO details/summary html tag for accordion/collapsible section
// https://markodenic.com/css-tips/?source=reddit
