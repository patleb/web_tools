export const DEFAULT_CALLBACKS = {
  on_start: () => {},
  on_previous_step: (current_step) => {},
  on_next_step: (current_step) => {},
  on_stop: () => {},
  on_skip: () => {},
  on_finish: () => {}
}

export const DEFAULT_OPTIONS = {
  labels: {
    button_skip: 'Skip tour',
    button_previous: 'Previous',
    button_next: 'Next',
    button_stop: 'Finish'
  },
  enabled_buttons: {
    button_skip: true,
    button_previous: true,
    button_next: true,
    button_stop: true
  },
  start_timeout: 0,
}

export const DEFAULT_STEP_OPTIONS = {
  enabled_buttons: DEFAULT_OPTIONS.enabled_buttons,
  modifiers: [
    { name: 'arrow', options: { element: '.tour_step_arrow' } }
  ],
  placement: 'bottom'
}

export const KEYS = {
  ARROW_RIGHT: 39,
  ARROW_LEFT: 37,
  ESCAPE: 27
}
