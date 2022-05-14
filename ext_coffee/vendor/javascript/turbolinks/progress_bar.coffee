class Turbolinks.ProgressBar
  ANIMATION_DURATION = 300

  @default_css: """
    .turbolinks-progress-bar {
      position: fixed;
      display: block;
      top: 0;
      left: 0;
      height: 3px;
      background: #0076ff;
      z-index: 9999;
      transition: width #{ANIMATION_DURATION}ms ease-out, opacity #{ANIMATION_DURATION / 2}ms #{ANIMATION_DURATION / 2}ms ease-in;
      transform: translate3d(0, 0, 0);
    }
  """

  constructor: ->
    @stylesheet = @create_stylesheet()
    @progress = @create_progress()

  show: ->
    unless @visible
      @visible = true
      @install_stylesheet()
      @install_progress()
      @start_trickling()

  hide: ->
    if @visible and not @hiding
      @hiding = true
      @fade_progress =>
        @uninstall_progress()
        @stop_trickling()
        @visible = false
        @hiding = false

  set_value: (@value) ->
    @refresh()

  # Private

  install_stylesheet: ->
    document.head.insertBefore(@stylesheet, document.head.firstChild)

  install_progress: ->
    @progress.style.width = 0
    @progress.style.opacity = 1
    document.documentElement.insertBefore(@progress, document.body)
    @refresh()

  fade_progress: (callback) ->
    @progress.style.opacity = 0
    setTimeout(callback, ANIMATION_DURATION * 1.5)

  uninstall_progress: ->
    if @progress.parentNode
      document.documentElement.removeChild(@progress)

  start_trickling: ->
    @trickle_interval ?= setInterval(@trickle, ANIMATION_DURATION)

  stop_trickling: ->
    clearInterval(@trickle_interval)
    @trickle_interval = null

  trickle: =>
    @set_value(@value + Math.random() / 100)

  refresh: ->
    requestAnimationFrame =>
      @progress.style.width = "#{10 + (@value * 90)}%"

  create_stylesheet: ->
    element = document.createElement('style')
    element.type = 'text/css'
    element.textContent = @constructor.default_css
    element

  create_progress: ->
    element = document.createElement('div')
    element.className = 'turbolinks-progress-bar'
    element
