<template>
  <div class="step" id="guide" ref="guide">
    <div v-if="header" class="step_header">
      <div v-html="header"></div>
    </div>

    <div class="step_content">
      <div v-html="content"></div>
    </div>

    <div class="step_buttons">
      <button v-if="!is_last && button_enabled('button_quit')" @click.prevent="quit" class="step_button step_button_quit">
        {{ $t('guide.button_quit') }}
      </button>
      <button v-if="!is_first && button_enabled('button_previous')" @click.prevent="previous" class="step_button step_button_previous">
        {{ $t('guide.button_previous') }}
      </button>
      <button v-if="!is_last && button_enabled('button_next')" @click.prevent="next" class="step_button step_button_next">
        {{ $t('guide.button_next') }}
      </button>
      <button v-if="is_last && button_enabled('button_stop')" @click.prevent="finish" class="step_button step_button_stop">
        {{ $t('guide.button_stop') }}
      </button>
    </div>

    <div class="step_arrow" :class="{ step_arrow_dark: header }"></div>
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
    'guide_on_quit',
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
        this.guide_on_start(this.target)
      },
      next: function () {
        if (!this.is_last) {
          this.current_step_i++
          this.refresh()
          this.step_on_next(this.target)
          this.guide_on_next(this.target)
        }
      },
      previous: function () {
        if (!this.is_first) {
          this.step_on_previous(this.target)
          this.guide_on_previous(this.target)
          this.current_step_i--
          this.refresh()
        }
      },
      quit: function () {
        this.step_on_quit(this.target)
        this.guide_on_quit(this.target)
        this.stop()
      },
      finish: function () {
        this.guide_on_finish(this.target)
        this.stop()
      },
      stop: function () {
        document.body.classList.remove('current_tour')
        this.step_on_stop(this.target)
        this.guide_on_stop(this.target)
        this.reset()
      },
      refresh: function () {
        this.reset(CURRENT_TOUR)
        _.each(this.steps[this.current_step_i], (value, name) => {
          this[_.startsWith(name, 'on_') ? `step_${name}` : name] = value
        })
        if (this.target) {
          if (this.popper) {
            this.popper.destroy()
          }
          this.$nextTick(() => {
            this.$nextTick(() => {
              let popper_params = _.merge({}, $store_defaults.guide.popper_params, this.popper_params)
              this.popper = createPopper(this.target, this.$refs.guide, popper_params)
            })
          })
        } else {
          console.log(`Step not found: [${this.id ? `#${this.id}` : `.${this.class}`}]`)
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
          // this.is_first ? this.quit() : this.previous()
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
      target: function () {
        return this.id ? document.getElementById(this.id) : _.first(document.getElementsByClassName(this.class))
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
          document.body.classList.remove(`step_${old_id}`)
        }
        if (new_id) {
          document.body.classList.add(`step_${new_id}`)
        }
      },
      class: function (new_class, old_class) {
        if (old_class) {
          document.body.classList.remove(`step_${old_class}`)
        }
        if (new_class) {
          document.body.classList.add(`step_${new_class}`)
        }
      },
      scope: function (new_scope, old_scope) {
        if (old_scope) {
          document.body.classList.remove(`scope_${old_scope}`)
        }
        if (new_scope) {
          document.body.classList.add(`scope_${new_scope}`)
        }
      }
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
  @import '~@@/mix_template/stylesheets/globals';

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
