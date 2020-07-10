export default {
  guide: {
    guide_open: true,
    current_tour: null,
    current_step_i: null,
    steps: [],
    id: null,
    class: null,
    header: null,
    content: null,
    enabled_buttons: {},
    popper_params: {
      modifiers: [
        { name: 'arrow', options: { element: '.step_arrow' } }
      ],
      placement: 'bottom'
    },
    guide_on_start: () => {},
    guide_on_previous: () => {},
    guide_on_next: () => {},
    guide_on_stop: () => {},
    guide_on_quit: () => {},
    guide_on_finish: () => {},
    step_on_previous: () => {},
    step_on_next: () => {},
    step_on_stop: () => {},
    step_on_quit: () => {},
  }
}
