# frozen_string_literal: true

prepend :sidebar, [
  page_sidebar,
]
append :data, [
  div_('.js_routes', data: { paths: MixPage.routes }),
  div_('.js_page_uuid', data: { uuid: @page.uuid })
]
extends 'layouts/application', [
  yield,
]
