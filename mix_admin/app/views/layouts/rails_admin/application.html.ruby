append :meta do
  meta_ name: 'robots', contents: 'NONE,NOARCHIVE'
end

append :body_begin, [
  div_('#js_i18n_translations', data: { translations: js_i18n('admin.js') }),
  div_('#js_routes_paths', data: { paths: RailsAdmin.js_routes }),
]

append :sidebar, [
  ul_('.nav.nav-pills.nav-stacked', main_navigation),
  ul_('.nav.nav-pills.nav-stacked', static_navigation),
  hr_('.separator'),
  ul_('.nav.nav-pills.nav-stacked', [
    li_(login_link),
    li_(edit_user_link),
    li_(back_to_site_link),
    li_(locale_select),
    li_(account_select),
    li_(remote_console_link),
    li_(logout_link)
  ])
]

append :body_end do
  remote_console
end

extends 'layouts/mr_template/application' do
  render_pjax
end
