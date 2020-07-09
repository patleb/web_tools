<template>
  <div>
    <div v-show="guide_open" class="step" id="guide" ref="guide">
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
        <button @click.prevent="previous" v-if="!is_first && button_enabled('button_previous')" class="step_button step_button_previous">
          {{ $t('guide.button_previous') }}
        </button>
        <button @click.prevent="next" v-if="!is_last && button_enabled('button_next')" class="step_button step_button_next">
          {{ $t('guide.button_next') }}
        </button>
        <button @click.prevent="finish" v-if="is_last && button_enabled('button_stop')" class="step_button step_button_stop">
          {{ $t('guide.button_stop') }}
        </button>
      </div>

      <div class="step_arrow" :class="{ step_arrow_dark: header }"></div>
    </div>
  </div>
</template>

<script>
  import { createPopper } from '@popperjs/core'

  const START = 0
  const CURRENT_TOUR = [
    'current_tour',
    'current_step_i',
    'steps',
    'guide_on_start',
    'guide_on_previous',
    'guide_on_next',
    'guide_on_previous',
    'guide_on_stop',
    'guide_on_skip',
    'guide_on_finish',
  ]

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
        document.body.classList.add('current_tour')
        this.current_step_i = START
        this.refresh()
        this.guide_on_start()
      },
      next: function () {
        if (!this.is_last) {
          this.current_step_i++
          this.refresh()
          this.step_on_next()
          this.guide_on_next()
        }
      },
      previous: function () {
        if (!this.is_first) {
          this.current_step_i--
          this.refresh()
          this.step_on_previous()
          this.guide_on_previous()
        }
      },
      skip: function () {
        this.step_on_skip()
        this.guide_on_skip()
        this.stop()
      },
      finish: function () {
        this.guide_on_finish()
        this.stop()
      },
      stop: function () {
        document.body.classList.remove('current_tour')
        this.step_on_stop()
        this.guide_on_stop()
        this.reset()
      },
      refresh: function () {
        this.reset(CURRENT_TOUR)
        _.each(this.steps[this.current_step_i], (value, name) => {
          this[_.startsWith(name, 'on_') ? `step_${name}` : name] = value
        })
        let target = this.selector ? document.querySelector(this.selector) : document.getElementById(this.id)
        if (target) {
          if (this.popper) {
            this.popper.destroy()
          }
          this.$nextTick(() => {
            this.$nextTick(() => {
              let popper_params = _.merge({}, $store_defaults.guide.popper_params, this.popper_params)
              this.popper = createPopper(target, this.$refs.guide, popper_params)
            })
          })
        } else {
          console.log(`Step #id not found: [${this.selector || this.id}]`)
          this.stop()
          this.popper = null
        }
      },
      reset: function (except = []) {
        _.each(_.omit($store_defaults.guide, except), (value, name) => { this[name] = value })
      },
      on_keyup: function (event) {
        if (event.defaultPrevented) {
          return
        }
        switch (event.key) {
        case "Enter":
        case "Right":
        case "ArrowRight":
          // this.is_last ? this.finish() : this.next()
          this.next()
          break
        case "Left":
        case "ArrowLeft":
          // this.is_first ? this.skip() : this.previous()
          this.previous()
          break
        case "Esc":
        case "Escape":
          this.stop()
          break
        }
        event.preventDefault()
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
      current_tour: function (new_tour, old_tour) {
        if (old_tour) {
          this.stop()
        }
        if (new_tour) {
          _.each(new_tour, (value, name) => {
            this[_.startsWith(name, 'on_') ? `guide_${name}` : name] = value
          })
          this.start()
        }
      },
      id: function (new_id, old_id) {
        if (old_id) {
          document.body.classList.remove(`current_step_${old_id}`)
        }
        if (new_id) {
          document.body.classList.add(`current_step_${new_id}`)
        }
      },
    },
  }
</script>

<style lang="scss">
  .current_tour {
    pointer-events: none;
  }

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
    background: $foreground_color;
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
    border-color: $foreground_color;
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
  }

  @media (hover: hover) {
    .step_button:hover {
      background-color: rgba(255, 255, 255, 0.95);
      color: $foreground_color;
    }
  }
</style>
