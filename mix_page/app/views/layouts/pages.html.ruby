append :data, [
  div_('.js_routes',    data: { value: MixPage.routes }),
  div_('.js_page_uuid', data: { value: @page.uuid })
]
prepend :sidebar, [
  page_sidebar,
]
prepend :footer, [
  pagination
]
extends 'layouts/application', [
  yield,
]
