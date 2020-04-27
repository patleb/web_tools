<template>
  <div class="tour_step" :id="`tour_step_${id}`" :ref="`tour_step_${id}`">
    <slot name="header">
      <div v-if="step.header" class="tour_step_header">
        <div v-if="step.header.title" v-html="step.header.title"></div>
      </div>
    </slot>

    <slot name="content">
      <div class="tour_step_content">
        <div v-html="step.content"></div>
      </div>
    </slot>

    <slot name="actions">
      <div class="tour_step_buttons">
        <button @click.prevent="skip" v-if="!is_last && button_enabled('button_skip')" class="tour_step_button tour_step_button_skip">
          {{ labels.button_skip }}
        </button>
        <button @click.prevent="previous_step" v-if="!is_first && button_enabled('button_previous')" class="tour_step_button tour_step_button_previous">
          {{ labels.button_previous }}
        </button>
        <button @click.prevent="next_step" v-if="!is_last && button_enabled('button_next')" class="tour_step_button tour_step_button_next">
          {{ labels.button_next }}
        </button>
        <button @click.prevent="finish" v-if="is_last && button_enabled('button_stop')" class="tour_step_button tour_step_button_stop">
          {{ labels.button_stop }}
        </button>
      </div>
    </slot>

    <div class="tour_step_arrow" :class="{ tour_step_arrow_dark: step.header && step.header.title }"></div>
  </div>
</template>

<script>
  import { createPopper } from '@popperjs/core'
  import { DEFAULT_STEP_OPTIONS } from '@@/mix_template/config/tour_defaults'

  export default {
    props: {
      step:            { type: Object },
      previous_step:   { type: Function },
      next_step:       { type: Function },
      stop:            { type: Function },
      skip:            { type: Function, default: function () { this.stop() } },
      finish:          { type: Function, default: function () { this.stop() } },
      is_first:        { type: Boolean },
      is_last:         { type: Boolean },
      labels:          { type: Object },
      enabled_buttons: { type: Object },
    },
    data: function () {
      return {
        id: this.step.id,
      }
    },
    computed: {
      params: function () {
        return {
          ...DEFAULT_STEP_OPTIONS,
          ...{ enabled_buttons: Object.assign({}, this.enabled_buttons) },
          ...this.step.params
        }
      }
    },
    methods: {
      create_step: function () {
        if (this.target) {
          createPopper(this.target, this.$refs[`tour_step_${this.id}`], this.params)
        } else {
          console.log(`Step not found: [${this.id}]`)
          this.stop()
        }
      },
      button_enabled: function (name) {
        return this.params.enabled_buttons.hasOwnProperty(name) ? this.params.enabled_buttons[name] : true
      }
    },
    mounted: function () {
      this.target = document.getElementById(this.step.id)
      this.create_step()
    },
  }
</script>

<style lang="scss" scoped>
  .tour_step {
    min-width: 160px;
    background: #50596c; /* #ffc107, #35495e */
    color: white;
    max-width: 320px;
    border-radius: 3px;
    filter: drop-shadow(0 0 2px rgba(0, 0, 0, 0.5));
    padding: 1rem;
    text-align: center;
    z-index: 10000;
  }

  .tour_step .tour_step_arrow {
    width: 0;
    height: 0;
    border-style: solid;
    position: absolute;
    margin: 0.5rem;
  }

  .tour_step .tour_step_arrow {
    border-color: #50596c; /* #ffc107, #35495e */
  }

  .tour_step_arrow_dark {
    border-color: #454d5d;
  }

  .tour_step[data-popper-placement^="top"] {
    margin-bottom: 0.5rem;
  }

  .tour_step[data-popper-placement^="top"] .tour_step_arrow {
    border-width: 0.5rem 0.5rem 0 0.5rem;
    border-left-color: transparent;
    border-right-color: transparent;
    border-bottom-color: transparent;
    bottom: -0.5rem;
    left: calc(50% - 1rem);
    margin-top: 0;
    margin-bottom: 0;
  }

  .tour_step[data-popper-placement^="bottom"] {
    margin-top: 0.5rem;
  }

  .tour_step[data-popper-placement^="bottom"] .tour_step_arrow {
    border-width: 0 0.5rem 0.5rem 0.5rem;
    border-left-color: transparent;
    border-right-color: transparent;
    border-top-color: transparent;
    top: -0.5rem;
    left: calc(50% - 1rem);
    margin-top: 0;
    margin-bottom: 0;
  }

  .tour_step[data-popper-placement^="right"] {
    margin-left: 0.5rem;
  }

  .tour_step[data-popper-placement^="right"] .tour_step_arrow {
    border-width: 0.5rem 0.5rem 0.5rem 0;
    border-left-color: transparent;
    border-top-color: transparent;
    border-bottom-color: transparent;
    left: -0.5rem;
    top: calc(50% - 1rem);
    margin-left: 0;
    margin-right: 0;
  }

  .tour_step[data-popper-placement^="left"] {
    margin-right: 0.5rem;
  }

  .tour_step[data-popper-placement^="left"] .tour_step_arrow {
    border-width: 0.5rem 0 0.5rem 0.5rem;
    border-top-color: transparent;
    border-right-color: transparent;
    border-bottom-color: transparent;
    right: -0.5rem;
    top: calc(50% - 1rem);
    margin-left: 0;
    margin-right: 0;
  }

  /* Custom */

  .tour_step_header {
    margin: -1rem -1rem 0.5rem;
    padding: 0.5rem;
    background-color: #454d5d;
    border-top-left-radius: 3px;
    border-top-right-radius: 3px;
  }

  .tour_step_content {
    margin: 0 0 1rem 0;
  }

  .tour_step_button {
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
      background-color: rgba(white, 0.95);
      color: #50596c;
    }
  }
</style>
