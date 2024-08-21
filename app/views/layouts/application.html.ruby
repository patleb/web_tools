# frozen_string_literal: true

# append :fonts, preload_pack_asset('application')
append :javascripts, javascript_pack_tag!('application', defer: true, 'data-turbolinks-track': 'reload')
append :stylesheets, stylesheet_pack_tag!('application', media: :all, 'data-turbolinks-track': 'reload')
append :metas, meta_(name: 'turbolinks-cache-control', content: 'no-preview')
append :header, [
  flash_message(:alert),
  flash_message(:notice),
]
append :sidebar, [
  user_login_link,
  user_logout_button
]
extends 'layouts/lib' do
  yield
end
