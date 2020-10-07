append :stylesheets, [
  stylesheet_link_tag("https://cdn.jsdelivr.net/npm/katex@#{RailsAdmin.config.katex_version}/dist/katex.min.css", media: :all),
]

append :fonts, [
  link_(rel: 'preconnect', href: 'https://cdn.jsdelivr.net', crossorigin: 'anonymous'),
  preload_link_tag_bootswatch_fonts(:paper),
  preload_link_tag("https://cdn.jsdelivr.net/npm/katex@#{RailsAdmin.config.katex_version}/dist/fonts/KaTeX_Main-Regular.woff2"),
  preload_link_tag("https://cdn.jsdelivr.net/npm/katex@#{RailsAdmin.config.katex_version}/dist/fonts/KaTeX_Math-Italic.woff2"),
]

append :metas do
  meta_ name: 'robots', contents: 'NONE,NOARCHIVE'
end

append :html_data, [
  div_('#js_i18n_translations', data: { translations: js_i18n(:pjax, :template, :admin) }),
  div_('#js_routes_paths', data: { paths: RailsAdmin.js_routes }),
]

append :sidebar, [
  ul_('.nav.nav-pills.nav-stacked', main_navigation),
  ul_('.nav.nav-pills.nav-stacked', static_navigation),
  hr_('.separator'),
  ul_('.nav.nav-pills.nav-stacked', [
    li_(back_to_site_link),
    li_(login_link),
    li_(edit_user_link),
    li_(locale_select),
    li_(remote_console_link),
    li_(logout_link)
  ])
]

extends 'layouts/mix_template/main', [
  render_pjax,
  remote_console
]
