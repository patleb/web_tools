append :style do
  <<~CSS
    /* TODO */
  CSS
end

extends 'layouts/lib_mailer', [
  yield,
]
