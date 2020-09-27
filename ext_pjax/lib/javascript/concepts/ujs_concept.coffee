class Js.UjsConcept
  document_on: -> [
    'click.continue change.continue submit.continue', '[data-confirm]', (event) ->
      confirm = $(document.activeElement).data('confirm') ? $(event.currentTarget).data('confirm')
      unless confirm? && confirm != false && window.confirm(I18n.t('confirmation') || confirm)
        event.stopImmediatePropagation()
        false

    # Workaround for jquery-ujs formnovalidate issue: https://github.com/rails/jquery-ujs/issues/316
    'click.continue', '[formnovalidate]', ->
      $(this).closest('form').attr(novalidate: true).data(novalidate: true)

    'click', 'a[data-method], [data-href]', (event) ->
      link = $(event.currentTarget)
      href = $.parse_location(link).href
      form = form$(method: 'post', action: href)
      inputs = input_(name: '_method', value: link.data('method') || 'GET', type: 'hidden')
      csrf_token = $.csrf_token()
      csrf_param = $.csrf_param()
      if csrf_param? && csrf_token? && !$.is_cross_domain(href)
        inputs += input_(name: csrf_param, value: csrf_token, type: 'hidden')
      target = link.attr('target')
      form.attr(target: target) if target
      (link.data('params') ? {}).each (param_key, param_value) ->
        if param_value?.is_a(Object)
          param_value.flatten_keys('][').each (keys, value) ->
            inputs += input_(name: [param_key, '[', keys, ']'].join(''), value: value, type: 'hidden')
        else
          inputs += input_(name: param_key, value: param_value, type: 'hidden')
      form.hide().append(inputs).appendTo('body')
      form.submit()
      false
  ]

  ready_once: ->
    $.error('cannot be used with rails-ujs!') if window.Rails?
    window.Rails = {}

    $.error('cannot be used with jquery-ujs!') if $.rails?
    $.rails = {}

  ready: ->
    $("form input[name='#{$.csrf_param()}']").val($.csrf_token())
