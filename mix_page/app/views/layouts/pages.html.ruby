# frozen_string_literal: true

append :data, [
  div_('.js_routes', data: { paths: MixPage.routes }),
  div_('.js_page_uuid', data: { uuid: @page.uuid })
]
append :footer, [
  pagination
]
prepend :sidebar, [
  page_sidebar,
]
extends 'layouts/application', [
  yield,
]
