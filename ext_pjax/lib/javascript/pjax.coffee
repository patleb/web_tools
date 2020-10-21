class Js.Pjax
  @CONTAINER: '#js_pjax_container'
  @TITLE: '#js_pjax_title'
  @VIRTUAL_FILE: 'input:file.js_pjax_virtual_file'
  @INPUT_FILE: 'input:file:not(.js_pjax_virtual_file,.se-input-form)'
  @DISABLE_SUBMIT: '[data-disable="submit"]'
  @DISABLE_CLICK: '[data-disable="click"]'

  @initialize: (options = {}) =>
    $.error('cannot be used with turbolinks!') if window.Turbolinks?
    window.Turbolinks = {}

    # For stubbing purpose in tests
    @location_replace = window.location.replace.bind(window.location)
    @history_push_state = window.history.pushState.bind(window.history)
    @history_replace_state = window.history.replaceState.bind(window.history)

    @reset(window.history.state, options)

    $.pjax = @send
    $.pjax.reload = @reload
    $(window).on 'popstate.pjax', @back_or_forward
    $(document).on 'click.pjax', '.pjax', @click
    $(document).on 'submit.pjax', 'form', (event) =>
      remote = $(document.activeElement).data('remote') ? $(event.currentTarget).data('remote')
      if remote? && remote != false
        @submit(event)
      else
        @disable_buttons()

  @reset: (state, options = {}) =>
    @abort_if_pending()
    @defaults = {
      method: 'GET'
      data: {}
      dataType: 'html'
      pjax: true
      scroll_to: 0
      push: true
      replace: false
      max_cache_length: 20
    }.merge(options)
    @xhr = null
    @options = null
    @container = null
    unless (@current_state = state)
      @current_state = { uid: $.unique_id(), url: window.location.href, title: document.title }
      window.history.replaceState(@current_state, document.title)
    @previous_state = null
    @cache_mapping = {}
    @cache_forward_stack = []
    @cache_back_stack = []

  @click: (event) =>
    return if event.isDefaultPrevented()
    return if $.is_meta_click(event)

    link$ = $(event.currentTarget)
    link = $.parse_location(link$)
    return if $.is_cross_domain(link)
    return if $.is_hash_of_location(link)

    options = { url: link.href, target: link$ }
    options.disable = link$ if link$.data('disable') == 'click'
    return if $.fire(link$, 'pjax:click', [this, options]) == false

    @send(options)
    event.preventDefault()
    $.fire(link$, 'pjax:clicked', [this])
    false

  @submit: (event) =>
    form = $(event.currentTarget)
    form.find(@VIRTUAL_FILE).each$ (input) -> input.clear_value()
    options = { target: form }
    button = $(document.activeElement)
    if button.is('button')
      button_name = button.attr('name')
      options.disable = button if button.data('disable') == 'click'
    if button_name == '_cancel'
      data = form.find(':input:hidden').serializeArray()
      data.push(name: button_name, value: button.val())
    else
      data = form.serializeArray()
      if (files = form.find(@INPUT_FILE)).length
        files.each (i, file) ->
          for j in [(data.length - 1)..0] by -1
            data.splice(j, 1) if (data[j].name == file.name)
        (options.headers ||= {})['X-PJAX-FILE'] = true
        data.push(name: '_pjax_file', value: true)
        options.iframe = true
        options.files = files
        options.processData = false
      data.push(name: button_name, value: button.val()) if button_name
    options.method = (button.attr('formmethod') || form.attr('method') || 'GET').upcase()
    options.url = url = button.attr('formaction') || form.attr('action')
    options.data = data
    options.crossDomain = $.is_cross_domain(url)
    if button.data('pjax') == false || form.data('pjax') == false
      options.pjax = false
      options.data.push(name: '_pjax', value: false)

    Js.prepend_to options, 'beforeSend', @disable_buttons
    Js.prepend_to options, 'complete', @enable_buttons
    return if $.fire(form, 'pjax:submit', [this, options]) == false

    @send(options)
    event.preventDefault()
    $.fire(form, 'pjax:submitted', [this])
    false

  @reload: (options = {}) =>
    @send({ url: @current_url(), push: false, replace: true, scroll_to: false }.merge(options))

  @back_or_forward: (event) =>
    @abort_if_pending()
    return @location_reload(location.href) unless (@container = $(@CONTAINER)).length
    return unless (next_state = event.originalEvent.state)? # Must have a pre-existing pjax history session.
    return if @current_state.uid == next_state.uid # Ignore hash change or initial separate history session popstate.

    forward = @current_state.uid < next_state.uid
    new_contents = @cache_mapping[next_state.uid]
    old_contents = @container.clone().contents()
    @fire_clone(old_contents)
    cache_pop(forward, @current_state.uid, old_contents)
    @fire_popstate(next_state, forward)

    if new_contents?
      @fire_start()
      @previous_state = @current_state
      @current_state = next_state
      @title_replace(next_state.title)
      @fire_replace(new_contents)
      @container.html(new_contents)
      @fire_end()
    else
      @send(uid: next_state.uid, url: next_state.url, push: false, scroll_to: false)

    # Force reflow/relayout before the browser tries to restore the scroll position.
    @container[0].offsetHeight

  @send: (options) =>
    options = $.ajaxSettings.deep_merge(@defaults, options)
    options.url = options.url() if options.url.is_a(Function)
    if options.pjax
      unless (@container = $(@CONTAINER)).length
        throw "no pjax container for #{@CONTAINER}"
      (options.headers ||= {})['X-PJAX'] = true
      # Make sure to have a separate browser cache for pjax requests.
      if options.data.is_a(Array) then options.data.push(name: '_pjax', value: true) else options.data._pjax = true
      Js.prepend_to options, 'beforeSend', @on_before_send
      Js.prepend_to options, 'error', @on_error
      Js.prepend_to options, 'success', @on_success
    else
      @container = options.target
      Js.prepend_to options, 'beforeSend', @fire_before_send
      Js.prepend_to options, 'error', @fire_error
      Js.prepend_to options, 'success', @fire_success
    Js.prepend_to options, 'complete', @fire_complete

    @abort_if_pending()
    @options = options
    @xhr = $.ajax(options)

    if @xhr.readyState > $.AJAX_UNSENT
      if options.pjax && options.push && !options.replace
        old_contents = @container.clone().contents()
        old_contents.each$ (content) =>
          content.find_all(".#{$.ONCE}").remove_once()
          content.find_all(".#{$.DISABLE}#{@DISABLE_SUBMIT},.#{$.DISABLE}#{@DISABLE_CLICK}").remove_disable() if options.disable
        @fire_clone(old_contents)
        cache_push(@current_state.uid, old_contents)
        @history_push_state(null, "", options.request_url)
      @fire_start()
      @fire_send()

    @xhr

  #### PRIVATE ####

  @abort_if_pending: =>
    if @xhr?.readyState < $.AJAX_DONE
      @xhr.onreadystatechange = _.noop
      @xhr.abort()

  @on_before_send: (xhr, options) =>
    return false if @fire_before_send(xhr, options) == false

    url = $.parse_location(options.url)
    url.search = @strip_pjax_params(url.search)
    url.href = url.href.sub(/\?($|#)/, '$1')

    @options.request_url = url.href
    @options.hash = url.hash

  @on_error: (xhr, status, error) =>
    return if @fire_error(xhr, status, error) == false
    return if status == 'abort'

    if (json = JSON.safe_parse(xhr.responseText))
      xhr.responseJSON = json
      @scroll()
    else if Env.development && xhr.status == 500
      $('html').empty()
      $('html').html(xhr.responseText.simple_format())
    else if (container = @extract_container(xhr.responseText, xhr)).contents
      @on_success(xhr.responseText, status, xhr)
    else if @options.method == 'GET'
      @location_reload(container.url)
    else
      Flash.error(I18n.t('error'))

  @on_success: (data, status, xhr) =>
    current_version = $('meta[http-equiv="X-PAGE-VERSION"]').attr('content')
    latest_version = xhr.getResponseHeader('X-PAGE-VERSION')
    container = @extract_container(data, xhr)
    container.url = $.parse_location(container.url, hash: @options.hash).href unless container.redirect
    return @location_reload(container.url) if current_version && latest_version && current_version != latest_version
    return @location_reload(container.url) unless container.contents

    @previous_state = @current_state
    @current_state = { uid: @options.uid || $.unique_id(), url: container.url, title: container.title }

    if @options.push || @options.replace
      @history_replace_state(@current_state, container.title, container.url)

    @blur()
    @title_replace(container.title)
    @fire_replace(container.contents)
    @container.html(container.contents)
    @focus()
    @scroll()
    @fire_success(data, status, xhr) unless 400 <= xhr.status < 600

  @location_reload: (url) =>
    @fire_reload(url)
    @history_replace_state(null, "", @current_state.url)
    @location_replace(url)

  @current_url: ->
    window.location.href

  @title_replace: (title) ->
    document.title = title if title?.present()

  @extract_container: (data, xhr) =>
    if (redirect = xhr.getResponseHeader('X-PJAX-REDIRECT'))
      @options.request_url = @strip_pjax_params($.parse_location(redirect).href)
    container = { url: @options.request_url, redirect }
    return container if /<html[\s>]/i.test(data)
    return container unless (contents = $($.parseHTML(data))).length
    container.contents = contents
    container.title = contents.filter(@TITLE).data('title')?.strip()
    container

  @blur: =>
    # Only blur the focus if the focused element is within the container.
    if $.contains(@CONTAINER, document.activeElement)
      try document.activeElement.blur() catch e then null

  @focus: =>
    # FF bug: Won't autofocus fields that are inserted via JS. If theres no current focus, autofocus the last field.
    autofocus = @container.find('input[autofocus], textarea[autofocus]').last()[0]
    if autofocus && document.activeElement != autofocus
      autofocus.focus()

  @scroll: =>
    scroll_to =
      if @options.hash?.present()
        name = decodeURIComponent(@options.hash[1..])
        hash = document.getElementById(name) || document.getElementsByName(name)[0]
        $(hash).offset().top if hash
      else
        @options.scroll_to
    if scroll_to?.is_a(Number)
      $(window).scrollTop(scroll_to)
      @fire_scroll(scroll_to, !!hash)

  @disable_buttons: =>
    # Slight timeout so that the submit button gets properly serialized
    setTimeout(=>
      $(@DISABLE_SUBMIT).add_disable()
    , 13)

  @enable_buttons: =>
    setTimeout(=>
      $(@DISABLE_SUBMIT).remove_disable()
    , 13)

  @fire_before_send: (xhr, options) =>
    $.fire(@container, 'pjax:before_send', [this, options])

  @fire_error: (xhr, status, error) =>
    $.fire(@container, 'pjax:error', [this, status, error])

  @fire_success: (data, status, xhr) =>
    $.fire(@container, 'pjax:success', [this, data, status])

  @fire_complete: (xhr, status) =>
    $.fire(@container, 'pjax:complete', [this, status])
    @fire_end()

  @fire_start: =>
    $.fire(@container, 'pjax:start', [this])

  @fire_send: =>
    $.fire(@container, 'pjax:send', [this])

  @fire_clone: (contents) =>
    $.fire(@container, 'pjax:clone', [this, contents])

  @fire_reload: (url) =>
    $.fire(@container, 'pjax:reload', [this, url])

  @fire_replace: (contents) =>
    $.fire(@container, 'pjax:replace', [this, contents])
    $.dom_leave()
    @container.empty()

  @fire_popstate: (state, forward) =>
    $.fire(@container, 'pjax:popstate', [this, state, forward])

  @fire_end: =>
    $.dom_ready()
    $.fire(@container, 'pjax:end', [this])

  @fire_scroll: (scroll_to, hash) =>
    $.fire(@container, 'pjax:scroll', [this, scroll_to, hash])

  @strip_pjax_params: (url) ->
    url.gsub(/_pjax\w*=\w+(&|$)/, '').sub(/[?&]$/, '')

  cache_push = (uid, value) =>
    @cache_mapping[uid] = value
    @cache_back_stack.push(uid)
    trim_cache_stack(@cache_forward_stack, 0) # Remove all entries in forward history stack after pushing a new page.
    trim_cache_stack(@cache_back_stack, @defaults.max_cache_length)

  cache_pop = (forward, uid, value) =>
    @cache_mapping[uid] = value
    [push_stack, pop_stack] =
      if forward
        [@cache_back_stack, @cache_forward_stack]
      else
        [@cache_forward_stack, @cache_back_stack]
    push_stack.push(uid)
    delete_cache_entry pop_stack.pop()
    trim_cache_stack(push_stack, @defaults.max_cache_length)

  trim_cache_stack = (stack, length) ->
    while (stack.length > length)
      delete_cache_entry stack.shift()

  delete_cache_entry = (uid) =>
    return unless uid
    if (contents = @cache_mapping[uid])
      contents.each$ (content) -> content.remove()
    delete @cache_mapping[uid]
