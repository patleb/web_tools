append :data, [
  div_('.js_action', data: { value: @action.name }),
  div_('.js_model',  data: { value: @model&.to_param }),
  div_('.js_routes', data: { value: MixAdmin.routes }),
]
append :header, [
  admin_actions_menu,
  @section&.search_menu,
  @section&.scroll_menu,
]
prepend :sidebar, [
  admin_sidebar,
]
extends 'layouts/application' do
  yield
end
