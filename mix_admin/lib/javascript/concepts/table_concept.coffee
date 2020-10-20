class RailsAdmin.TableConcept
  sort_head_timeout = null

  constants: =>
    PAGINATE_SEPARATOR: RailsAdmin.PaginateConcept
    WRAPPER: 'CLASS'
    ROW_HEAD: 'CLASS'
    COLUMN_HEAD: 'CLASS'
    COLUMN: 'CLASS'
    ALL_LOADED: 'CLASS'
    SORTABLE: 'pjax'
    SORT_UP: ''
    SORT_DOWN: ''
    DISABLED_SORT: => "._#{@COLUMN_HEAD_CLASS}._#{@SORTABLE}"
    ENABLED_SORT: => ".#{@COLUMN_HEAD_CLASS}.#{@SORTABLE}"
    SCROLL_UP: 'CLASS'
    # SCROLL_X: 'CLASS' # TODO might still need it when table is wide
    STICKY_HEAD: 'CLASS'
    STICKY_COLUMN: 'CLASS'
    STICKY_COLUMN_HEAD: 'CLASS'
    FROZEN_COLUMN: 'CLASS'
    REMOVE_COLUMN: 'CLASS'
    MOVE_COLUMN: 'CLASS'
    RESTORE_COLUMNS: 'CLASS'
    EXPAND_CELL: 'CLASS'
    COLLAPSE_CELL: 'CLASS'
    LESS_CONTENT: 'CLASS'
    MORE_CONTENT: 'CLASS'
    FULL_CONTENT: 'CLASS'

  accessors: ->
    table_head:               -> @table_wrapper.find('thead')
    table_first_frozen:       -> @table_wrapper.find("#{@FROZEN_COLUMN}:first")
    sticky_head:              -> @find_or_prepend(@STICKY_HEAD)
    sticky_head_table:        -> @sticky_head().find('.table')
    sticky_column:            -> @find_or_prepend(@STICKY_COLUMN)
    sticky_column_first:      -> @sticky_column().find("#{@FROZEN_COLUMN}:first")
    sticky_column_head:       -> @find_or_prepend(@STICKY_COLUMN_HEAD)
    sticky_column_head_first: -> @sticky_column_head().find(@FROZEN_COLUMN)
    scroll_up:                -> $(@SCROLL_UP)

  document_on: => [
    'click', @SCROLL_UP, =>
      Layout.animate(scrollTop: 0)

    'click', @EXPAND_CELL, (event, target) =>
      @expand_content(target)

    'click', @COLLAPSE_CELL, (event, target) =>
      @collapse_content(target)

    'click', @REMOVE_COLUMN, (event, target) =>
      name = target.parent().data('name')
      @remove_column(name)

    'click', @RESTORE_COLUMNS, =>
      @clear_cookies()
      $.pjax.reload()

    'pjax:click', @COLUMN_HEAD, (event, pjax, options, target) =>
      return unless $(@ALL_LOADED).length
      @sort_column(target)
      false

    'sortupdate', @ROW_HEAD, (event, { item }) =>
      name = item.data('name')
      @move_column(name)
  ]

  ready: =>
    return unless (@table_wrapper = $(@WRAPPER)).length

    @has_first_frozen = !!@table_first_frozen().length
    @create_sticky_head()        if @sticky_head().is(':empty')
    @create_sticky_column_head() if @has_first_frozen && @sticky_column_head().is(':empty')
    @create_sticky_column()      if @has_first_frozen && @sticky_column().is(':empty')

    @sm_sticky_head = new Js.StateMachine.Hideable 'table_sticky_head', {
      visible_on: =>
        @table_top() < $(window).scrollTop()
      states:
        visible: enter: =>
          @sticky_head().show()
          @sticky_column_head().show() if @sm_sticky_column.is('visible')
          @scroll_up().show()
          @table_head().fadeTo(0, 0)
        hidden: enter: =>
          @sticky_head().hide()
          @sticky_column_head().hide()
          @scroll_up().hide()
          @table_head().fadeTo(0, 1)
    }
    SmStickyColumn = @has_first_frozen && Js.StateMachine.Hideable || Js.StateMachine.Null
    @sm_sticky_column = new SmStickyColumn 'table_sticky_column', {
      visible_on: =>
        @table_first_frozen().offset().left < @sticky_column_first().offset().left
      states:
        visible: enter: =>
          @update_sticky_column_top()
          @sticky_column().css(visibility: 'visible')
          @sticky_column().find('a').show()
          @sticky_column_head().show() if @sm_sticky_head.is('visible')
        hidden: enter: =>
          @sticky_column().find('a').hide()
          @sticky_column().css(visibility: 'hidden')
          @sticky_column_head().hide()
    }

    @sm_sticky_head.trigger('ready')
    @sm_sticky_column.trigger('ready')
    @refresh()

    Layout.on 'scroll.table', _.throttle(@on_window_scroll)
    $(window).on 'resize.table', _.throttle(@refresh)
    @table_wrapper.on 'scroll', _.throttle(@on_table_scroll)

    @table_wrapper.find(@ROW_HEAD).sortable(
      items: @MOVE_COLUMN, axis: 'x', tolerance: 'pointer', cursor: 'grabbing', helper: 'clone', placeholder: 'none'
      cursorAt: left: 0
    )
    @set_scroll_x()

  leave: =>
    Layout.off 'scroll.table'
    $(window).off 'resize.table'
    @table_wrapper?.off 'scroll'
    @unset_scroll_x()

  enable_sort: =>
    unless sort_head_timeout
      sort_head_timeout = setTimeout(=>
        $(@DISABLED_SORT).toggleClass("_#{@COLUMN_HEAD_CLASS} _#{@SORTABLE} #{@COLUMN_HEAD_CLASS} #{@SORTABLE}")
      , 200)

  disable_sort: =>
    $(@ENABLED_SORT).toggleClass("#{@COLUMN_HEAD_CLASS} #{@SORTABLE} _#{@COLUMN_HEAD_CLASS} _#{@SORTABLE}")
    clearTimeout(sort_head_timeout)
    sort_head_timeout = null

  refresh: =>
    return unless Main.index_action || Main.trash_action
    @update_sticky_head()
    @on_window_scroll()
    @update_sticky_column_height()
    @on_table_scroll()
    true

  table_head_names: (table_head = @table_head()) =>
    table_head.find(@COLUMN_HEAD).map$((th) -> th.data('name'))

  #### PRIVATE ####

  expand_content: (target) =>
    cell = target.parent()
    if (full_content = cell.find(@FULL_CONTENT)).length
      cell.find(@LESS_CONTENT).css(visibility: 'hidden')
      full_content.show()[0].scrollWidth
    else
      cell.find(@MORE_CONTENT).show()[0].scrollWidth
    target.hide()
    cell.find(@COLLAPSE_CELL).show()
    @refresh()

  collapse_content: (target) =>
    cell = target.parent()
    if (full_content = cell.find(@FULL_CONTENT)).length
      cell.find(@LESS_CONTENT).css(visibility: 'visible')
      full_content.hide()
    else
      cell.find(@MORE_CONTENT).hide()
    target.hide()
    cell.find(@EXPAND_CELL).show()
    @refresh()

  set_scroll_x: =>
    @scroll_x = [@table_head(), @sticky_head()].each_with_object [], (head, memo) =>
      return unless head?
      scroll_x = Hamster(head[0]).wheel (event, delta, delta_x, delta_y) =>
        event.preventDefault()
        @table_wrapper.scrollLeft(@table_wrapper.scrollLeft() - (20 * delta_y))
      memo.push(scroll_x)
    $(@COLLAPSE_CELL).each$ (element) =>
      scroll_x = Hamster(element[0]).wheel (event, delta, delta_x, delta_y) =>
        event.preventDefault()
        content = element.nextAll("#{@MORE_CONTENT},#{@FULL_CONTENT}").first()
        content.scrollLeft(content.scrollLeft() - (20 * delta_y))
      @scroll_x.push(scroll_x)

  unset_scroll_x: =>
    @scroll_x?.each (scroll_x) -> scroll_x.unwheel()

  clear_cookies: ->
    Main.cookie_remove('remove', 'move')

  on_window_scroll: =>
    @update_sticky_column_top()
    @sm_sticky_head.trigger('toggle')

  on_table_scroll: =>
    @sticky_head_table().css(left: - @table_wrapper.scrollLeft())
    @sm_sticky_column.trigger('toggle')

  create_sticky_head: =>
    table = @table_wrapper.find('table').clone()
    table.find('tbody').remove()
    table.find('th').removeClass("#{@SORTABLE} #{@SORT_UP} #{@SORT_DOWN}")
    @sticky_head().html(table)

  create_sticky_column_head: =>
    table = @sticky_head_table().clone()
    table.find("th:not(#{@FROZEN_COLUMN})").remove()
    @sticky_column_head().html(table)

  create_sticky_column: =>
    table = @table_wrapper.find('table').clone()
    table.find("th:not(#{@FROZEN_COLUMN}),td:not(#{@FROZEN_COLUMN})").remove()
    table.find('th').removeClass("#{@SORTABLE} #{@SORT_UP} #{@SORT_DOWN}")
    @sticky_column().html(table)

  update_sticky_head: =>
    @sticky_head().css(width: "#{@table_wrapper.outerWidth()}px")
    columns = @sticky_head().find('th')
    @table_head().find('tr:first > th').each$ (cell, i) =>
      width = "#{cell.outerWidth()}px"
      $(columns[i]).css(width: width)
      @sticky_column_head_first().css(width: width) if i == 1 # skip bulk column
    @sticky_column_head().css(height: "#{@sticky_head().outerHeight()}px")

  update_sticky_column_height: =>
    rows = @sticky_column().find(@FROZEN_COLUMN)
    @table_wrapper.find(@FROZEN_COLUMN).each$ (cell, i) =>
      height = "#{cell.outerHeight()}px"
      $(rows[i]).css(height: height)
      @sticky_column_head_first().css(height: height) if i == 0

  update_sticky_column_top: =>
    @sticky_column().css(top: @table_top())

  sort_column: (head) =>
    classes = head.classes()
    sort_up = classes.any (name) => name == @SORT_UP
    type = switch classes.find((name) -> !name.start_with('js_') && name.end_with('_type')).sub(/_type$/, '')
      when 'boolean'                               then 'to_b'
      when 'integer', 'foreign_key'                then 'to_i'
      when 'date', 'datetime', 'time', 'timestamp' then 'to_timestamp'
      when 'decimal', 'float'                      then 'to_f'
      else                                              'to_s'
    name = head.data('name')
    rows = @table_wrapper.find("tbody > tr.#{Main.model_key}_row")
    values = rows.each_with_object [], (row, memo, i) =>
      cell = row.find("#{@COLUMN}_#{name}")
      row.removeClass(@PAGINATE_SEPARATOR).detach()
      memo.push [cell.text()[type](), i]
    values = values.sort_by ([value, i]) -> value
    @table_head().find('th').removeClass("#{@SORT_UP} #{@SORT_DOWN}")
    if sort_up
      head.addClass(@SORT_DOWN)
    else
      head.addClass(@SORT_UP)
      values.reverse()
    table_body = @table_wrapper.find('tbody')
    if @has_first_frozen
      sticky_rows = @sticky_column().find("tbody > tr.#{Main.model_key}_row")
      sticky_rows.each$ (row) => row.removeClass(@PAGINATE_SEPARATOR).detach()
      sticky_table_body = @sticky_column().find('tbody')
    values.each ([value, i]) =>
      table_body.prepend(rows[i])
      sticky_table_body.prepend(sticky_rows[i]) if @has_first_frozen

  remove_column: (name) =>
    $("#{@COLUMN}_#{name}").remove()
    @refresh()
    @save_column('remove', name)

  move_column: (name) =>
    index = @table_head_names().index(name) + 1
    sticky_cell = @sticky_head().find("#{@COLUMN}_#{name}").detach()
    @sticky_head().find("th:nth-of-type(#{index})").after(sticky_cell)
    body_cells = @table_wrapper.find("tbody #{@COLUMN}_#{name}").detach()
    @table_wrapper.find("td:nth-of-type(#{index})").each$ (td, i) -> td.after(body_cells[i])
    @save_column('move', name)

  save_column: (type, name) =>
    list = Main.cookie_get(type)
    list[name] = 1
    Main.cookie_set(type, list)
    @update_moved_columns()

  update_moved_columns: =>
    names = @table_head_names()
    list = Main.cookie_get('move')
    list = list.each_with_object {}, (column, _, h) ->
      if (index = names.index(column))
        h[column] = index
    Main.cookie_set('move', list)

  table_top: =>
    @table_wrapper.offset().top

  find_or_prepend: (selector) =>
    unless (element = $(selector)).length
      @table_wrapper.before(div$(selector))
      element = $(selector)
    element
