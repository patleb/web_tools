# frozen_string_literal: true

# append :fonts, preload_pack_asset('app')
append :javascripts, javascript_pack_tag!('app', defer: true, 'data-turbolinks-track': 'reload')
append :stylesheets, stylesheet_pack_tag!('app', media: :all, 'data-turbolinks-track': 'reload')
append :metas, meta_(name: 'turbolinks-cache-control', content: 'no-preview')
append :sidebar do
  ul_ [
    li_('.menu_divider'),
    li_(admin_link),
    li_(user_link),
  ]
end
extends 'layouts/lib' do
  yield
end
