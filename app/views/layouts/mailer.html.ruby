append :style do
  <<~CSS
    /* TODO */
  CSS
end

extends 'layouts/main_mailer', [
  yield,
]
