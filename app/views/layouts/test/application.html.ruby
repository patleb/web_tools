# append :fonts, preload_pack_asset('test')
append :javascripts, javascript_pack_tag!('test', defer: true, 'data-turbolinks-track': 'reload')
append :stylesheets, stylesheet_pack_tag!('test', media: :all, 'data-turbolinks-track': 'reload')
append :header, [
  flash_message(:alert),
  flash_message(:notice),
]
extends 'layouts/lib' do
  yield
end
