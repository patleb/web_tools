append :data, [
  div_('.js_routes', data: { paths: MixPage.routes }),
  div_('.js_page_uuid', data: { uuid: @page.uuid })
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
