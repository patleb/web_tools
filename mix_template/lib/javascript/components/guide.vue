<template>
  <div id="guide" class="step" ref="guide">
    <div v-if="header" class="step_header">
      <div v-html="header"></div>
    </div>

    <div class="step_content">
      <div v-html="content"></div>
    </div>

    <div class="step_buttons">
      <button @click.prevent="skip" v-if="!is_last && button_enabled('button_skip')" class="step_button step_button_skip">
        {{ $t('guide.button_skip') }}
      </button>
      <button @click.prevent="previous_step" v-if="!is_first && button_enabled('button_previous')" class="step_button step_button_previous">
        {{ $t('guide.button_previous') }}
      </button>
      <button @click.prevent="next_step" v-if="!is_last && button_enabled('button_next')" class="step_button step_button_next">
        {{ $t('guide.button_next') }}
      </button>
      <button @click.prevent="finish" v-if="is_last && button_enabled('button_stop')" class="step_button step_button_stop">
        {{ $t('guide.button_stop') }}
      </button>
    </div>

    <div class="step_arrow" :class="{ step_arrow_dark: header }"></div>
  </div>
</template>

<script>
  import { createPopper } from '@popperjs/core'

  const KEYS = {
    ARROW_RIGHT: 39,
    ARROW_LEFT: 37,
    ESCAPE: 27
  }
  const START = 0

  export default {
    mounted: function () {
      window.addEventListener('keyup', this.on_keyup)
    },
    beforeDestroy: function () {
      window.removeEventListener('keyup', this.on_keyup)
    },
    methods: {
      button_enabled: function (name) {
        return _.has(this.enabled_buttons, name) ? this.enabled_buttons[name] : true
      },
      start: function () {
        this.current_step_i = START
        this.refresh()
        this.on_start()
      },
      previous_step: function () {
        if (!this.is_first) {
          this.current_step_i--
          this.refresh()
          this.on_previous_step()
        }
      },
      next_step: function () {
        if (!this.is_last) {
          this.current_step_i++
          this.refresh()
          this.on_next_step()
        }
      },
      stop: function () {
        this.on_stop()
        this.reset()
      },
      skip: function () {
        this.on_skip()
        this.stop()
      },
      finish: function () {
        this.on_finish()
        this.stop()
      },
      refresh: function () {
        this.reset(['current_tour', 'current_step_i', 'steps'])
        _.each(this.steps[this.current_step_i], (value, name) => { this[name] = value })
        const target = document.getElementById(this.id)
        if (target) {
          createPopper(target, this.$refs.guide, _.merge({}, $store_defaults.guide.popper_params, this.popper_params))
        } else {
          console.log(`Step #id not found: [${this.id}]`)
          this.stop()
        }
      },
      reset: function (except = []) {
        _.each(_.omit($store_defaults.guide, except), (value, name) => { this[name] = value })
      },
      on_keyup: function (e) {
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
    },
    computed: {
      is_first: function () {
        return this.current_step_i === START
      },
      is_last: function () {
        return this.current_step_i === _.size(this.steps) - 1
      },
      ...$store_accessors('guide'),
    },
    watch: {
      current_tour: function (tour) {
        if (tour) {
          this.steps = tour.steps
          this.start()
        }
      },
    },
  }
</script>

<style lang="scss">
  #guide {
    pointer-events: auto;
  }

  #popper {
    position: absolute;
    left: 0;
    top: 0;
  }
</style>

<style lang="scss" scoped>
  .step {
    min-width: 160px;
    background: $guide_background_color;
    color: white;
    max-width: 320px;
    border-radius: 3px;
    filter: drop-shadow(0 0 2px rgba(0, 0, 0, 0.5));
    padding: 1rem;
    text-align: center;
    z-index: 10000;
  }

  .step .step_arrow {
    width: 0;
    height: 0;
    border-style: solid;
    position: absolute;
    margin: 0.5rem;
  }

  .step .step_arrow {
    border-color: $guide_background_color;
  }

  .step_arrow_dark {
    border-color: #454d5d;
  }

  .step[data-popper-placement^="top"] {
    margin-bottom: 0.5rem;
  }

  .step[data-popper-placement^="top"] .step_arrow {
    border-width: 0.5rem 0.5rem 0 0.5rem;
    border-left-color: transparent;
    border-right-color: transparent;
    border-bottom-color: transparent;
    bottom: -0.5rem;
    left: calc(50% - 1rem);
    margin-top: 0;
    margin-bottom: 0;
  }

  .step[data-popper-placement^="bottom"] {
    margin-top: 0.5rem;
  }

  .step[data-popper-placement^="bottom"] .step_arrow {
    border-width: 0 0.5rem 0.5rem 0.5rem;
    border-left-color: transparent;
    border-right-color: transparent;
    border-top-color: transparent;
    top: -0.5rem;
    left: calc(50% - 1rem);
    margin-top: 0;
    margin-bottom: 0;
  }

  .step[data-popper-placement^="right"] {
    margin-left: 0.5rem;
  }

  .step[data-popper-placement^="right"] .step_arrow {
    border-width: 0.5rem 0.5rem 0.5rem 0;
    border-left-color: transparent;
    border-top-color: transparent;
    border-bottom-color: transparent;
    left: -0.5rem;
    top: calc(50% - 1rem);
    margin-left: 0;
    margin-right: 0;
  }

  .step[data-popper-placement^="left"] {
    margin-right: 0.5rem;
  }

  .step[data-popper-placement^="left"] .step_arrow {
    border-width: 0.5rem 0 0.5rem 0.5rem;
    border-top-color: transparent;
    border-right-color: transparent;
    border-bottom-color: transparent;
    right: -0.5rem;
    top: calc(50% - 1rem);
    margin-left: 0;
    margin-right: 0;
  }

  .step_header {
    margin: -1rem -1rem 0.5rem;
    padding: 0.5rem;
    background-color: #454d5d;
    border-top-left-radius: 3px;
    border-top-right-radius: 3px;
  }

  .step_content {
    margin: 0 0 1rem 0;
  }

  .step_button {
    background: transparent;
    border: .05rem solid white;
    border-radius: .1rem;
    color: white;
    cursor: pointer;
    display: inline-block;
    font-size: 1.1rem;
    height: 1.8rem;
    line-height: 1rem;
    outline: none;
    margin: 0 0.2rem;
    padding: .35rem .4rem;
    text-align: center;
    text-decoration: none;
    transition: all .2s ease;
    vertical-align: middle;
    white-space: nowrap;

    &:hover {
      background-color: rgba(255, 255, 255, 0.95);
      color: $guide_background_color;
    }
  }
</style>
