class Js.PageLinkConcept
  constants: =>
    MODEL: ''
    ACTIVE: 'active'
    ACTIVE_WRAPPER: => ".nav.nav-pills li.#{@ACTIVE}"

  document_on: => [
    'pjax:click', '.pjax', (event, pjax, options, target) =>
      active_link = $("#{@ACTIVE_WRAPPER} a")
      active_href = $.strip_origin active_link.attr('href')
      link_href = $.strip_origin target.attr('href')
      if link_href != active_href
        if target.hasClass(@MODEL)
          active_link.parent().removeClass(@ACTIVE)
          target.parent().addClass(@ACTIVE)
        # back button cache: pjax does not blur elements outside the container
        target.blur()
  ]

  ready: =>
    $(@ACTIVE_WRAPPER).removeClass(@ACTIVE)
    $(".#{@MODEL}_#{Page.uuid}").parent().addClass(@ACTIVE)
