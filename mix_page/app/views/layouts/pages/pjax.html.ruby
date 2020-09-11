extends('layouts/mix_template/main/pjax') {[
  div_('#js_page_uuid', data: { uuid: @page.uuid }),
  yield
]}
