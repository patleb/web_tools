h_(
  div_('#js_pjax_title', data: { title: @page_title }),
  div_('#js_pjax_body_id', data: { body_id: module_name }),
  div_('#js_flash_messages', data: { messages: flash }),
  query_diet,
  yield,
  pjax_recovery
)
