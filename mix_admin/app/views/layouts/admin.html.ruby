append :data, [
  div_('.js_action', data: { name: @action.name }),
  div_('.js_model', data: { name: @model&.to_param }),
  div_('.js_routes', data: { paths: MixAdmin.routes }),
]
append :header, [
  admin_actions_menu,
  @section&.search_menu,
  @section&.scroll_menu,
]
append :footer, div_(
  p_ ['Copyright', ascii(:copyright), Time.current.year, '- All rights reserved by', strong_(@meta[:app])]
)
prepend :sidebar, [
  admin_sidebar,
]
extends 'layouts/application' do
  yield
end
