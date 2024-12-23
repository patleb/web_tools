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
  '2xs-1': { max: '319px' }, // micro < 320
  'xs-1':  { max: '479px' }, // mini < 480
  'sm-1':  { max: `${parseInt(defaultTheme.screens.sm) - 1}px` }, // small < 640
  'md-1':  { max: `${parseInt(defaultTheme.screens.md) - 1}px` }, // phone < 768
  'lg-1':  { max: `${parseInt(defaultTheme.screens.lg) - 1}px` }, // tablet < 1024
  'xl-1':  { max: `${parseInt(defaultTheme.screens.xl) - 1}px` }, // laptop < 1280
  '2xl-1': { max: `${parseInt(defaultTheme.screens['2xl']) - 1}px` }, // desktop < 1536
  '2xs':   '320px', // >= 320
  'xs':    '480px', // >= 480
  ...defaultTheme.screens,
}
const plugin = require('tailwindcss/plugin')
const ext_css = ({ themes = true, darkTheme = 'dark' } = {}) => {
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
  return plugin(({ addBase, addComponents, theme }) => {
    addBase(colors)
    addComponents({
      '.line-clamp-wrap': {
        'white-space': 'pre-wrap',
        'overflow-wrap': 'break-word',
        'word-wrap': 'break-word',
      },
      '.scrollbar-sm': {
        '&::-webkit-scrollbar': {
          'width': '0.5rem',
          'height': '0.5rem',
        },
        '&::-webkit-scrollbar-thumb': {
          'background-color': theme('colors.gray.400'),
        },
        '&::-webkit-scrollbar-track': {
          'background-color': theme('colors.gray.200'),
        },
      },
      '.scrollbar-xs': {
        '&::-webkit-scrollbar': {
          'width': '0.375rem',
          'height': '0.375rem',
        },
        '&::-webkit-scrollbar-thumb': {
          'background-color': theme('colors.gray.400'),
        },
        '&::-webkit-scrollbar-track': {
          'background-color': theme('colors.gray.200'),
        },
      },
      '.border-right': {
        'border-right': '1px solid var(--base-300)',
      },
      '.border-left': {
        'border-left': '1px solid var(--base-300)',
      },
      '.border-active': {
        'border-color': 'hsl(var(--p) / var(--tw-border-opacity))',
      },
      '.box-shadow': {
        'box-shadow': '1px 1px 4px hsl(var(--n) / var(--tw-border-opacity))',
      },
    })
  })
}

module.exports = {
  themes,
  screens,
  ext_css,
}
