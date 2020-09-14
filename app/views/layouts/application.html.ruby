append :fonts, [
  preload_link_tag_bootswatch_fonts(:paper),
]

append :html_data, [
  div_('#js_i18n_translations', data: { translations: js_i18n }),
]

append :sidebar, [
  ul_('.nav.nav-pills.nav-stacked', [
    li_('.dropdown-header', t('template.navigation')),
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
