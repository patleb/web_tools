append :data, [
  div_('#js_i18n_translations', data: { translations: js_i18n(:pjax, :template, :page) }),
  div_('#js_routes_paths', data: { paths: MixServer.routes.merge(MixPage.config.js_routes) }),
]

append :sidebar, [
  area(:sidebar_links),
  hr_('.separator'),
  ul_('.nav.nav-pills.nav-stacked', [
    li_(user_view_link),
    li_(login_link),
    li_(edit_user_link),
    li_(locale_select),
    li_(logout_link)
  ])
]

extends 'layouts/mix_template/main', [
  yield,
]
