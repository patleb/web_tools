class RailsAdmin.Form.NestedFormConcept::Element
  constants: ->
    TOGGLE_OPENED: 'fa-chevron-down'
    TOGGLE_CLOSED: 'fa-chevron-right'
    ONE: ''
    LAST_BUTTON: ''
    TEMPLATE: 'ID'
    CHILD: ''
    NAV: '.nav'
    TAB_CONTENT: '.tab-content'
    TAB_PANE_ADDED: ''
    DESTROY: 'input[id$="__destroy"]'

  accessors: ->
    button_toggle: -> @wrapper.find_first(@TOGGLE)
    button_add:    -> @wrapper.find_first(@ADD)
    nav:           -> @wrapper.find_first(@NAV)
    icon:          -> @button_toggle().find('i')
    tab_content:   -> @wrapper.find_first(@TAB_CONTENT)

  constructor: (@wrapper) ->

  toggle_nav_tabs: =>
    @toggle_nav()
    @show_tab()

  create: =>
    nav_tab = @create_nav_tab()
    @show_tab(force: true, nav_tab: nav_tab)
    @hide_button_add_if_single_association()
    RailsAdmin.Form.FieldConcept.ready()

  destroy: (button_remove) =>
    nav_tab = @destroy_nav_tab_and_find_next(button_remove)
    @show_tab(first: false, force: true, nav_tab: nav_tab)
    @show_button_add_if_single_association()

  #### PRIVATE ####

  show_tab: ({ first = true, force = false, nav_tab = [] } = {}) =>
    if force && @closed()
      @toggle_nav(force_show: true)
    if nav_tab.length
      nav_tab.tab('show')
    unless @selected()
      if (nav_tab = @nav().find("a:#{if first then 'first' else 'last'}")).length
        nav_tab.tab('show')
      else
        @toggle_nav(force_close: true)

  toggle_nav: ({ force_show = false, force_close = false } = {}) =>
    if force_show || @closed()
      @button_toggle().remove_disable() if force_show
      @open_nav()
    else
      @button_toggle().add_disable() if force_close
      @close_nav()

  closed: =>
    @icon().hasClass(@TOGGLE_CLOSED)

  selected: =>
    @nav().find('.active').length

  open_nav: =>
    @icon().removeClass(@TOGGLE_CLOSED).addClass(@TOGGLE_OPENED)
    @tab_content().fadeIn()
    @nav().fadeIn()

  close_nav: =>
    @icon().removeClass(@TOGGLE_OPENED).addClass(@TOGGLE_CLOSED)
    @tab_content().fadeOut()
    @nav().fadeOut()

  create_nav_tab: =>
    { id } = @button_add().data('association')
    { tab_pane_id, object_label } = @append_tab_pane(id)
    @append_nav_tab(tab_pane_id, object_label)

  destroy_nav_tab_and_find_next: (button_remove) =>
    tab_pane = button_remove.closest(@TAB_PANE)
    nav_tab_wrapper = @nav().find("a[href='##{tab_pane.attr('id')}']").parent()
    unless (next_nav_tab = nav_tab_wrapper.next().find('a')).length
      next_nav_tab = nav_tab_wrapper.prev().find('a')
    nav_tab_wrapper.remove()
    @destroy_record_and_tab_pane(tab_pane)
    next_nav_tab

  hide_button_add_if_single_association: =>
    if @button_add().hasClass(@ONE)
      @button_add().hide()
      @button_toggle().addClass(@LAST_BUTTON)

  show_button_add_if_single_association: =>
    if @button_add().is(':hidden')
      @button_add().show()
      @button_toggle().removeClass(@LAST_BUTTON)

  append_tab_pane: (association_id) =>
    child_index = $.unique_id()
    { template, object_label } = $("#{@TEMPLATE}_#{association_id}").data('form')
    template = template.gsub(///(\[|_)#{@CHILD}_#{association_id}(\]|_)///, "$1#{child_index}$2")
    tab_pane_id = "tab_#{association_id}_#{child_index}"
    @tab_content().append(
      div_ id: tab_pane_id, class: "#{@TAB_PANE_ADDED} tab-pane fade",
        template.html_safe(true)
    )
    { tab_pane_id, object_label }

  append_nav_tab: (tab_pane_id, object_label) =>
    nav_tab_wrapper =
      li$ ->
        a_ href: "##{tab_pane_id}", data: { toggle: 'tab' },
          object_label
    @nav().append(nav_tab_wrapper)
    nav_tab_wrapper.find('a')

  destroy_record_and_tab_pane: (tab_pane) =>
    tab_pane.find_first(@DESTROY).val(1)
    if tab_pane.hasClass(@TAB_PANE_ADDED)
      tab_pane.remove()
    else
      tab_pane.removeAttr('class').addClass('hidden')
      tab_pane.find('[required]').each ->
        $(this).removeAttr('required')
