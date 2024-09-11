# frozen_string_literal: true

append :data, div_('.js_model', data: { name: @model&.to_param })
prepend :header, [
  admin_actions_menu,
  @section&.search_menu,
  @section&.scroll_menu,
]
append :footer, div_(
  p_ ['Copyright', ascii(:copyright), Time.current.year, '- All rights reserved by', strong_(@meta[:app])]
)
prepend :sidebar, [
  ul_(li_ admin_link),
  admin_sidebar,
]
extends 'layouts/application' do
  yield
end
