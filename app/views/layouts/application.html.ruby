append :fonts, [
  preload_icons,
  preload_fonts,
]
append :javascripts, javascript_pack_tag!('app', defer: true, 'data-turbolinks-track': 'reload')
append :stylesheets, stylesheet_pack_tag!('app', media: :all, 'data-turbolinks-track': 'reload')
append :metas, meta_(name: 'turbolinks-cache-control', content: 'no-preview')
append(:sidebar) {[
  ul_([
    li_('.menu_divider'),
    app_link,
    website_link,
    error_link,
    admin_link,
    admin_user_link,
    user_link,
    li_('.menu_divider'),
    user_role_select,
    locale_select,
    theme_select,
  ]),
]}
extends 'layouts/lib' do
  yield
end
