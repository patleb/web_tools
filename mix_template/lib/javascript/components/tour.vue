<template>
  <div class="tour">
    <slot
      :current_step="current_step"
      :steps="steps"
      :previous_step="previous_step"
      :next_step="next_step"
      :stop="stop"
      :skip="skip"
      :finish="finish"
      :is_first="is_first"
      :is_last="is_last"
      :labels="custom_options.labels"
      :enabled_buttons="custom_options.enabled_buttons"
    >
      <tour-step
        v-if="steps[current_step]"
        :step="steps[current_step]"
        :key="current_step"
        :previous_step="previous_step"
        :next_step="next_step"
        :stop="stop"
        :skip="skip"
        :finish="finish"
        :is_first="is_first"
        :is_last="is_last"
        :labels="custom_options.labels"
        :enabled_buttons="custom_options.enabled_buttons"
      />
    </slot>
  </div>
</template>

<script>
  import { DEFAULT_CALLBACKS, DEFAULT_OPTIONS, KEYS } from '@@/mix_template/config/tour_defaults'

  export default {
    props: {
      steps:     { type: Array, default: () => [] },
      name:      { type: String },
      options:   { type: Object, default: () => { return DEFAULT_OPTIONS } },
      callbacks: { type: Object, default: () => { return DEFAULT_CALLBACKS } }
    },
    data: function () {
      return {
        current_step: -1
      }
    },
    mounted: function () {
      this.$tours[this.name] = this
      window.addEventListener('keyup', this.handle_keyup)
    },
    beforeDestroy: function () {
      window.removeEventListener('keyup', this.handle_keyup)
    },
    computed: {
      // Allow us to define custom options and merge them with the default options.
      // Since options is a computed property, it is reactive and can be updated during runtime.
      custom_options: function () {
        return {
          ...DEFAULT_OPTIONS,
          ...this.options
        }
      },
      custom_callbacks: function () {
        return {
          ...DEFAULT_CALLBACKS,
          ...this.callbacks
        }
      },
      is_first: function () {
        return this.current_step === 0
      },
      is_last: function () {
        return this.current_step === this.steps.length - 1
      },
      steps_count: function () {
        return this.steps.length
      }
    },
    methods: {
      start: function (startStep) {
        // Wait for the DOM to be loaded, then start the tour
        setTimeout(() => {
          this.custom_callbacks.on_start()
          this.current_step = typeof startStep !== 'undefined' ? parseInt(startStep, 10) : 0
        }, this.custom_options.start_timeout)
      },
      previous_step: function () {
        if (this.current_step > 0) {
          this.custom_callbacks.on_previous_step(this.current_step)
          this.current_step--
        }
      },
      next_step: function () {
        if (this.current_step < this.steps_count - 1 && this.current_step !== -1) {
          this.custom_callbacks.on_next_step(this.current_step)
          this.current_step++
        }
      },
      stop: function () {
        this.custom_callbacks.on_stop()
        this.current_step = -1
      },
      skip: function () {
        this.custom_callbacks.on_skip()
        this.stop()
      },
      finish: function () {
        this.custom_callbacks.on_finish()
        this.stop()
      },
      handle_keyup: function (e) {
        switch (e.keyCode) {
        case KEYS.ARROW_RIGHT:
          this.next_step()
          break
        case KEYS.ARROW_LEFT:
          this.previous_step()
          break
        case KEYS.ESCAPE:
          this.stop()
          break
        }
      }
    }
  }
</script>

<style lang="scss">
  .tour {
    pointer-events: auto;
  }

  #popper {
    position: absolute;
    left: 0;
    top: 0;
  }
</style>
