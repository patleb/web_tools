jQuery.extend
  AJAX_UNSENT: 0
  AJAX_DONE: 4
  REPORT_VALIDITY: $('<form>')[0].reportValidity?
  PROGRESS_BAR_DEBOUNCE: 500
  progress_bar_timeout: null
  ready_list: []
  leave_list: []
  request_id: 0
  class_name: 'jQuery'

jQuery.define_singleton_methods
  dom_ready: ->
    $($.ready_list).each(-> this())

  dom_leave: ->
    $($.leave_list).each(-> this())

  fire: (target, type, args, props = {}) ->
    props.relatedTarget = target
    event = $.Event(type, props)
    target.trigger(event, args)
    !event.isDefaultPrevented()

  unique_id: ->
    "#{$.now().to_s().ljust(13, '0')}#{_.uniqueId().to_s()[0..2].rjust(3, '0')}"

  selected_text: ->
    text =
      if window.getSelection
        window.getSelection()
      else if document.getSelection
        document.getSelection()
      else if document.selection
        document.selection.createRange().text
      else
    text ?= ''
    text.toString()

  flat_params: (data) ->
    params = {}
    if data.is_a(String)
      data = decodeURIComponent(data).sub(/^\?/, '')
      data.split('&').except('').each (pair) ->
        [name, value] = pair.split('=')
        if /\[\]$/.match(name)
          params[name] ?= []
          params[name].push value
        else
          params[name] = value
    else
      params = $.flat_params($.param(data))
    params

  merge_params: (object, sources...) ->
    object.merge(sources.map (source) -> $.flat_params(source))

  query_params: (object) ->
    $.param object.each_with_object {}, (key, value, memo) ->
      memo[key] = if value?.is_a(String) then value else JSON.stringify(value)

  parse_location: (url, options = {}) ->
    if url.is_a(jQuery)
      if url.is('a')
        location = url[0]
      else
        location = document.createElement('a')
        href = location.href = url.data('href')
        unless href?
          throw "$.parse_location requires an anchor element, href attribute or url"
    else if url.is_a(String)
      location = document.createElement('a')
      location.href = url
    else
      location = url
    # IE bug workaround.
    location.href = location.href
    location.hash = options.hash if options.hash
    location

  is_cross_domain: (url) ->
    origin = document.createElement('a')
    origin.href = location.href
    check = (origin, request) ->
      # If URL protocol is false or is a string containing a single colon
      # *and* host are false, assume it is not a cross-domain request
      # (should only be the case for IE7 and IE compatibility mode).
      # Otherwise, evaluate protocol and host of the URL against the origin
      # protocol and host.
      !(
        ((!request.protocol || request.protocol == ':') && !request.host) ||
          ("#{origin.protocol}//#{origin.host}" == "#{request.protocol}//#{request.host}")
      )
    return check(origin, url) unless url.is_a(String)

    request = document.createElement('a')
    try
      request.href = url
      # This is a workaround to a IE bug.
      request.href = request.href
      check(origin, request)
    catch e
      # If there is an error parsing the URL, assume it is crossDomain.
      true

  is_hash_of_location: (url) ->
    url.href.includes('#') && $.strip_hash(url) == $.strip_hash(location)

  strip_hash: (url) ->
    url.href.replace(/#.*/, '')

  strip_origin: (url) ->
    url?.replace(location.origin, '')

  form_for: (data = {}) ->
    { "#{$.csrf_param()}": $.csrf_token() }.merge(data)

  form_valid: (inputs) ->
    inputs.to_a().all (input) ->
      $(input).valid()

  is_meta_click: (event) ->
    # TODO https://github.com/rails/rails/pull/34573/files
    # Middle click, cmd click, and ctrl click should open links in a new tab as normal.
    event.which > 1 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey

  is_submit_key: (event) ->
    event.which == $.ui.keyCode.ENTER && !$(event.target).is("textarea")

  csrf_token: ->
    # Up-to-date Cross-Site Request Forgery token
    $('meta[name=csrf-token]').attr('content')

  csrf_param: ->
    # URL param that must contain the CSRF token
    $('meta[name=csrf-param]').attr('content')

  load_progress_bar: ->
    unless $.progress_bar_timeout?
      $.progress_bar_timeout = setTimeout(->
        NProgress.start()
      , $.PROGRESS_BAR_DEBOUNCE)

  clear_progress_bar: ->
    NProgress.done()
    clearTimeout($.progress_bar_timeout)
    $.progress_bar_timeout = null

jQuery.define_methods
  is_a: (klass) ->
    this.constructor == klass

  to_a: ->
    this.toArray()

  to_s: ->
    this.to_a().map((item) -> item.outerHTML).join('')

  each_with_object: (accumulator, f_item_memo_index_self) ->
    f = (memo, item, index, self) ->
      f_item_memo_index_self($(item), memo, index, self)
      accumulator
    _.reduce(this, f, accumulator)

  map$: (f_item_index_self) ->
    f = (item, index, self) ->
      f_item_index_self($(item), index, self)
    this.to_a().map(f)

  each$: (f_item_index_self) ->
    f = (item, index, self) ->
      f_item_index_self($(item), index, self)
    this.to_a().each(f)

  clone_template: (handler = null) ->
    clone = this.children().first().clone()
    handler(clone) if handler?
    clone

  valid: ->
    if this.closest('form').data('novalidate') || this.attr('novalidate') || this[0].checkValidity?()
      true
    else if $.REPORT_VALIDITY
      this[0].reportValidity()
    else
      # check remotely
      true

  invalid: ->
    !this.valid()

  classes: ->
    (this.prop('class') || '').split(' ').except('')

  find_first: (selector) ->
    result = $()
    search = true
    if selector?.present()
      this.each ->
        queue = []
        queue.push($(this))
        while queue.length && search
          queue.shift().children().each ->
            child = $(this)
            if child.is(selector)
              result.push(child[0])
              search = false
            else
              queue.push(child)
        search
    result

  find_all: (selector, { remove = false } = {}) ->
    list = this.find(selector).addBack(selector)
    if remove
      excluded = list.remove()
      [list, this.not(excluded)]
    else
      list

  find_by: (condition) ->
    [attr, value] = condition.to_a().first()
    if value.is_a(Array)
      this.children().filter(-> value.includes(this[attr]))
    else
      this.find("[#{attr}='#{value.to_s().safe_text()}']")

  blank_inputs: (selector = 'input[name][required],textarea[name][required],select[name][required]', blank = true) ->
    found_inputs = $()
    checked_radio_button_names = {}
    for input in this.find(selector)
      input = $(input)
      if input.is('input[type="radio"]')
        # Don't count unchecked required radio as blank if other radio with same name is checked,
        # regardless of whether same-name radio input has required attribute or not. The spec
        # states https://www.w3.org/TR/html5/forms.html#the-required-attribute
        radio_name = input.attr('name')
        # Skip if we've already seen the radio with this name.
        unless checked_radio_button_names[radio_name]
          # If none checked
          unless this.find("input[type='radio']:checked[name='#{radio_name}']").length
            radios_for_name_with_none_selected = this.find("input[type='radio'][name='#{radio_name}']")
            found_inputs = found_inputs.add(radios_for_name_with_none_selected)
          # We only need to check each name once.
          checked_radio_button_names[radio_name] = radio_name
      else
        value_to_check =
          if input.is('input[type=checkbox],input[type=radio]')
            input.is(':checked')
          else
            !!input.val()
        unless value_to_check == blank
          found_inputs = found_inputs.add(input)
    if found_inputs.length
      found_inputs
    else
      false

  present_inputs: (selector = 'input[name][required],textarea[name][required],select[name][required]') ->
    this.blank_inputs(selector, false)

  get_value: ->
    switch this[0].type
      when 'checkbox', 'radio'
        this.is(':checked')
      else
        this.val()

  set_value: (value) ->
    switch this[0].type
      when 'checkbox', 'radio'
        this.prop(checked: value)
      when 'select-one'
        this.find(':selected').attr(selected: false)
        this.find_by(value: value).attr(selected: true)
      when 'select-multiple'
        this.children().filter(':selected').attr(selected: false)
        this.find_by(value: value).attr(selected: true)
      else
        this.attr(value: value)
    this.val(value)

  clear_value: ->
    switch this[0].type
      when 'checkbox', 'radio'
        this.prop(checked: false)
      when 'select-one'
        this.find(':selected').attr(selected: false)
      when 'select-multiple'
        this.children().filter(':selected').attr(selected: false)
    this.val(null)

  is_selected: (blank_value, selected = true) ->
    option = this[0]
    value = option.value
    return false if selected && !option.selected
    return false if !selected && option.selected
    return false unless value.present()
    if blank_value?.present()
      value != blank_value
    else
      true

  not_selected: (blank_value) ->
    this.is_selected(blank_value, false)

  cursor_start: (move = false) ->
    if move
      this[0].setSelectionRange?(0, 0)
      this
    else
      this[0].selectionStart || 0

  cursor_end: (move = false) ->
    if move
      caret_position = this.val().length * 2
      this[0].setSelectionRange?(caret_position, caret_position)
      this
    else
      this[0].selectionEnd || 0

  scroll_to: (item) ->
    if (item = $(item)).length
      this.scrollTop(this.scrollTop() - this.position().top + item.position().top)
    this

  has_scroll_y: ->
    this[0].scrollHeight > this[0].clientHeight

  has_scroll_x: ->
    this[0].scrollWidth > this[0].clientWidth

  hidden: ->
    this.is(':hidden') || this.css('visibility') == 'hidden' || this.css('opacity') == 0

  visible: ->
    !this.hidden()

jQuery.decorate_methods
  ready: (handler) ->
    $.ready_list.push(handler)
    this.super.apply(this, [-> handler()])

  submit: (args...) ->
    if args.length && !args[0].is_a(String)
      this.super.apply(this, args)
    else if this.data('novalidate') || this.attr('novalidate') || this[0].checkValidity?()
      this.super.apply(this, [])
    else if $.REPORT_VALIDITY
      this[0].reportValidity()
    else
      this.find("[type='submit'][name='#{args.shift() || '_save'}']").click()

jQuery.ajaxPrefilter (options, original_options, xhr) ->
  xhr.request_id = ++$.request_id

  unless options.crossDomain
    token = $.csrf_token()
    (options.headers ||= {})['X-CSRF-Token'] = token if token

  unless options.progress == false
    $.load_progress_bar()
    Js.prepend_to options, 'complete', (xhr, status) ->
      $.clear_progress_bar()

  unless options.flags == false
    {
      disable: [true,  'complete']
      once:    [true,  'complete']
      done:    [false, 'success']
      fail:    [false, 'error']
    }.each (flag_name, flag_options) ->
      [flag_present, after_result] = flag_options
      if options[flag_name]
        [before_action, after_action] = ["add_#{flag_name}", "remove_#{flag_name}"]
        [before_action, after_action] = [after_action, before_action] unless flag_present
        $(options[flag_name])[before_action]()
        Js.append_to options, after_result, (args...) ->
          $(options[flag_name])[after_action]()

['disable', 'once', 'done', 'fail'].each (flag) ->
  css_class = "js_#{flag}"
  jQuery[flag.toUpperCase()] = css_class

  jQuery.fn["has_#{flag}"] = ->
    this.hasClass(css_class)

  if flag == 'disable'
    jQuery.fn.add_disable = ->
      this.prop(disabled: true)
      this.each$ (e) -> e.prop(class: e.classes().add(css_class).join(' '))

    jQuery.fn.remove_disable = ->
      this.prop(disabled: false)
      this.each$ (e) -> e.prop(class: e.classes().except(css_class).join(' '))
  else
    jQuery.fn["add_#{flag}"] = ->
      this.each$ (e) -> e.prop(class: e.classes().add(css_class).join(' '))

    jQuery.fn["remove_#{flag}"] = ->
      this.each$ (e) -> e.prop(class: e.classes().except(css_class).join(' '))
