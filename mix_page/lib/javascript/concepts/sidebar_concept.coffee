class Js.SidebarConcept # TODO extract to MixTemplate with RailsAdmin.SidebarConcept
  constants: =>
    PAGE: ''
    ACTIVE: 'active'
    ACTIVE_WRAPPER: => ".nav.nav-pills li.#{@ACTIVE}"
    TOGGLE: 'CLASS'

  document_on: => [
    'pjax:click', '.pjax', (event, pjax, options, target) =>
      active_link = $("#{@ACTIVE_WRAPPER} a")
      active_href = $.strip_origin active_link.attr('href')
      link_href = $.strip_origin target.attr('href')
      if link_href != active_href
        if target.hasClass(@PAGE)
          active_link.parent().removeClass(@ACTIVE)
          target.parent().addClass(@ACTIVE)
        # back button cache: pjax does not blur elements outside the container
        target.blur()

    'click', @TOGGLE, (event, target) =>
      @toggle(target)
  ]

  ready: =>
    $(@ACTIVE_WRAPPER).removeClass(@ACTIVE)
    $(".#{@PAGE}_#{Page.uuid}").parent().addClass(@ACTIVE)
    $(@TOGGLE).each$ (target) =>
      if target.data('close')
        @toggle(target)

  toggle: (target) =>
    li = target.closest('li')
    children = li.nextAll("[data-node^='#{li.data('node')}/']")
    children.toggle()
    target.toggleClass(['fa-chevron-down', 'fa-chevron-right'])
