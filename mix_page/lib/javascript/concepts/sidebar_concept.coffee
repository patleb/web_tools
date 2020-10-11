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

  ready_once: =>
    $(@TOGGLE).reverse_each$ (target) =>
      li = target.closest('li')
      active_children = li.nextAll("[data-node^='#{li.data('node')}/']").children(".#{@PAGE}_#{Page.uuid}")
      if li.data('close') && active_children.length == 0
        @toggle(target)

  ready: =>
    $(@ACTIVE_WRAPPER).removeClass(@ACTIVE)
    $(".#{@PAGE}_#{Page.uuid}").parent().addClass(@ACTIVE)

  toggle: (target) =>
    li = target.closest('li')
    node = li.data('node')
    hidden_by = "#{@TOGGLE_CLASS}_by_#{node.full_underscore()}"
    if target.hasClass('fa-chevron-down')
      children = li.nextAll("[data-node^='#{node}/']:visible").addClass(hidden_by)
    else
      children = li.nextAll(".#{hidden_by}").removeClass(hidden_by)
    children.toggle()
    target.toggleClass(['fa-chevron-down', 'fa-chevron-right'])
