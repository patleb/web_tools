# frozen_string_literal: true

prepend :sidebar, [
  page_sidebar,
]
extends 'layouts/application', [
  yield,
]
