class RailsAdmin.Form.FieldConcept::DatetimepickerElement
  $.fn.datetimepicker.defaults.icons =
    time:     'fa fa-clock-o'
    date:     'fa fa-calendar'
    up:       'fa fa-chevron-up'
    down:     'fa fa-chevron-down'
    previous: 'fa fa-angle-double-left'
    next:     'fa fa-angle-double-right'
    today:    'fa fa-dot-circle-o'
    clear:    'fa fa-trash'
    close:    'fa fa-times'

  constructor: (@input) ->
    @input.datetimepicker @input.data('options')
