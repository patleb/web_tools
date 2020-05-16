export default {
  guide: {
    current_tour: null,
    current_step_i: null,
    steps: [],
    id: null,
    header: null,
    content: null,
    enabled_buttons: {},
    popper_params: {
      modifiers: [
        { name: 'arrow', options: { element: '.step_arrow' } }
      ],
      placement: 'bottom'
    },
    on_start: () => {},
    on_previous_step: () => {},
    on_next_step: () => {},
    on_stop: () => {},
    on_skip: () => {},
    on_finish: () => {},
  }
}
