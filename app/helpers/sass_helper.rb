module SassHelper
  # BOOTSWATCH_FONTS = {
  #   cyborg: 'https://fonts.googleapis.com/css?family=Roboto:400,700&display=swap',
  #   paper:  'https://fonts.googleapis.com/css?family=Roboto:300,400,500,700&display=swap',
  # }.freeze
  #
  # def preload_link_tag_bootswatch_fonts(theme)
  #   preload_link_tag(BOOTSWATCH_FONTS[theme.to_sym], as: 'style')
  # end

  def container(content = nil)
    menu_icon_class = { svg: { class: 'inline h-5 w-5' }, class: 'lg:hidden pr-1.5 cursor-pointer' }
    page_link_class = 'align-middle pr-1.5 text-primary font-medium'
    page_link_title = (['Website'] * 3).join(' ')
    [
      browser_navigation,
      div_('.drawer.drawer-mobile', class: 'h-screen') {[
        input_('#sidebar.drawer-toggle', type: 'checkbox'),
        div_('.drawer-content', class: 'scroll-smooth lg:border-l-2 p-4 flex flex-col justify-between gap-8') {[
          header_(class: '-mt-2') {[
            label_(class: 'lg:hidden w-72 pt-1', for: 'sidebar') {[
              icon('list', menu_icon_class),
            ]},
            a_(page_link_title, href: '', class: [page_link_class, 'lg:hidden']),
            contextual_navigation,
          ]},
          main_(class: 'flex flex-col flex-grow lg-1:self-center lg-1:mx-auto mr-auto gap-8') {[
            if block_given?
              yield
            else
              content
            end,
          ]},
          footer_('.footer.lg-1:footer-center', class: 'bg-base-100 text-base-content') do
            footer_navigation
          end
        ]},
        div_('.drawer-side', class: 'scroll-smooth') {[
          label_('.drawer-overlay', for: 'sidebar'),
          aside_(class: 'bg-base-100 w-72 overflow-y-auto') {[
            label_('.menu.menu-compact', class: 'pt-4 pb-2 px-4', for: 'sidebar') do
              span_{[
                icon('list', menu_icon_class),
                a_(page_link_title, href: '', class: page_link_class)
              ]}
            end,
            primary_navigation
          ]},
        ]},
      ]}
    ]
  end

  # back/forward/top/bottom/sections
  def browser_navigation
    div_('.dropdown.dropdown-end.dropdown-hover', class: 'fixed z-50 top-5 right-3 lg:right-4') {[
      label_(icon('three-dots-vertical', svg: { class: 'h-5 w-5' }), class: 'cursor-pointer', tabindex: 0),
      ul_('.dropdown-content.menu.menu-compact.rounded-box', class: 'shadow bg-base-100 w-max -mt-2') {[
        li_(a_ 'Item 1'),
        li_(a_ 'Item 2'),
      ]}
    ]}
  end

  # use tags instead of tree for pages
  # use tag_groups (ex.: pages in tag_0 and tag_1 and tag_2) to categorize pages
  # acutally, links would be list only, but could point to a tag, a tag_group or a page
  def primary_navigation
    nav_('.menu.menu-compact') {[
      ul_ {[
        li_(class: 'mt-0 h-0.5'),
        li_('.menu-title', span_('Navigation')),
        li_(a_ 'Sidebar Item 1'),
        li_(a_('Sidebar Item 2', class: 'text-primary'), class: 'bordered'),
        li_(a_('Sidebar Item N'), times: 10),
      ]}
    ]}
  end

  # replace by search bar in mix_page
  def contextual_navigation
    tab_text_class = '-mt-2 pl-0.5 md-1:hidden'
    icon_class = 'h-5 w-5 -mt-1 tooltip tooltip-bottom'

    nav_('.tabs', class: 'inline-flex align-middle lg-1:border-l-2 mt-3') {[
      a_('.tab.tab-bordered.tab-active', [icon('table', class: icon_class, data: { tip: 'Liste' }), span_('Liste', class: tab_text_class)]),
      a_('.tab.tab-bordered', [icon('filetype-csv', class: icon_class), span_('Exporter', class: tab_text_class)]),
      a_('.tab.tab-bordered', [icon('graph-up', class: icon_class), span_('Graphique', class: tab_text_class)]),
      a_('.tab.tab-bordered', [icon('trash', class: icon_class), span_('Corbeille', class: tab_text_class)]),
      a_('.tab.tab-bordered', [icon('plus', class: icon_class), span_('Ajouter', class: tab_text_class)]),
    ]}
  end

  def footer_navigation
    div_ do
      p_ "Copyright © #{Time.current.year} - All right reserved by ACME Industries Ltd"
    end
  end

  # TODO overflow-y only on table not the window ???
  # https://github.com/saadeghi/daisyui/issues/665
  def table
    [
      table_('.table.table-compact.table-zebra', class: 'shadow-xl') {[
        thead_(class: 'sticky -top-4') do
          tr_([
            th_([
              input_('.js_toggle_checkboxes.checkbox.checkbox-sm.checkbox-primary', class: 'absolute', type: 'checkbox', data: { targets: 'tbody .checkbox' }),
              span_('id', class: 'pl-9')
            ]),
            [th_('Name'), th_('Description')] * 1,
            th_('Last', class: 'pr-4')
          ])
        end,
        tbody_([
          tr_([
            th_([
              input_('.checkbox.checkbox-sm.checkbox-primary', type: 'checkbox', class: 'absolute'),
              span_(123, class: 'pl-9 font-normal')
            ]),
            [td_('the name'), td_('the description')] * 1,
            td_('the last', class: 'pr-4')
          ]),
        ] * 5)
      ]},
      table_pagination
    ]
  end

  def table_pagination
    [
      div_('.btn-group', class: 'gap-2') {[
        a_('.btn.btn-xs', '«', rel: 'prev', disabled: true),
        a_('.btn.btn-sm.btn-active', 1),
        a_('.btn.btn-xs', 2, rel: 'next'),
        a_('.btn.btn-xs', '…', disabled: true),
        a_('.btn.btn-xs', 5),
        a_('.btn.btn-xs', '»', rel: 'next'),
      ]},
      div_('.dropdown', class: 'w-fit') {[
        label_([span_('Per page'), span_('▼', class: 'pl-2 text-3xs')], class: 'text-xs bg-neutral text-neutral-content p-1.5 cursor-pointer', tabindex: 0),
        ul_('.dropdown-content.menu.menu-compact.rounded-box', class: 'shadow bg-base-100 w-max') {[
          li_(a_(25), class: 'text-xs'),
          li_(a_(50), class: 'text-xs'),
          li_(a_(100), class: 'text-xs'),
        ]}
      ]}
    ]
  end

  def filters

  end
end
