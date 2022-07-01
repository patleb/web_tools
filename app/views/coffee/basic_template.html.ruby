h_(
  header_('.container', [
    hgroup_{[
      h1_(a_ 'Basic template', href: '/coffee'),
      h2_('A basic custom template for Pico using only CSS custom properties (variables).')
    ]},
    nav_(
      ul_([
        li_(
          theme_menu(role: 'button', class: 'secondary')
        ),
        li_(
          examples_menu(role: 'button')
        ),
        li_(
          details_(role: 'list') {[
            summary_('aria-haspopup': 'listbox') {
              'Sections'
            },
            ul_(role: 'listbox') {[
              li_(a_ 'Search', href: '#search'),
              li_(a_ 'Preview', href: '#preview'),
              li_(a_ 'Typography', href: '#typography'),
              li_(a_ 'Buttons', href: '#buttons'),
              li_(a_ 'Form', href: '#form'),
              li_(a_ 'Tables', href: '#tables'),
              li_(a_ 'Accordions', href: '#accordions'),
              li_(a_ 'Article', href: '#article'),
              li_(a_ 'Progress', href: '#progress'),
              li_(a_ 'Loading', href: '#loading'),
            ]}
          ]}
        )
      ])
    )
  ]),
  main_('.container', [
    section_('#search', [
      h2_('Search'),
      form_tag('/coffee#search', method: :get) {[
        search_field_tag('search', params[:search], placeholder: 'Enter your search query here'),
      ]},
    ]),
    section_('#preview', [
      h2_('Preview'),
      p_('Sed ultricies dolor non ante vulputate hendrerit. Vivamus sit amet suscipit sapien. Nulla iaculis eros a elit pharetra egestas.'),
      form_([
        div_('.grid', [
          input_(type: 'text', name: 'firstname', placeholder: 'First name', 'aria-label': 'First name', required: true),
          input_(type: 'email', name: 'email', placeholder: 'Email address', 'aria-label': 'Email address', required: true),
          button_('Subscribe', type: 'submit', disabled: true)
        ]),
        fieldset_(
          label_(for: 'terms') {[
            input_('#terms', name: 'terms', type: 'checkbox', role: 'switch'),
            span_('I agree to the'),
            a_('Privacy Policy', href: '#')
          ]}
        )
      ])
    ]),
    section_('#typography', [
      h2_('Typography'),
      p_('Aliquam lobortis vitae nibh nec rhoncus. Morbi mattis neque eget efficitur feugiat. Vivamus porta nunc a erat mattis, mattis feugiat turpis pretium. Quisque sed tristique felis.'),
      blockquote_([
        '"Maecenas vehicula metus tellus, vitae congue turpis hendrerit non. Nam at dui sit amet ipsum cursus ornare."',
        footer_(
          cite_ '- Phasellus eget lacinia'
        )
      ]),
      h3_('Lists'),
      ul_([
        li_('Aliquam lobortis lacus eu libero ornare facilisis.'),
        li_('Nam et magna at libero scelerisque egestas.'),
        li_('Suspendisse id nisl ut leo finibus vehicula quis eu ex.'),
        li_('Proin ultricies turpis et volutpat vehicula.'),
      ]),
      h3_('Inline text elements'),
      div_('.grid', [
        p_(a_ 'Primary link', href: '#!'),
        p_(a_ '.secondary', 'Secondary link', href: '/coffee'),
        p_(a_ '.contrast', 'Contrast link', href: '#'),
      ]),
      div_('.grid', [
        p_(strong_ 'Bold'),
        p_(em_ 'Italic'),
        p_(u_ 'Underline'),
      ]),
      div_('.grid', [
        p_(del_ 'Deleted'),
        p_(ins_ 'Inserted'),
        p_(s_ 'Strikethrough'),
      ]),
      div_('.grid', [
        p_(small_ 'Small'),
        p_(['Text', sub_('Sub')]),
        p_(['Text', sup_('Sup')]),
      ]),
      div_('.grid', [
        p_(abbr_ 'Abbr.', title: 'Abbreviation', 'data-tooltip': 'Abbreviation'),
        p_(kbd_ 'Kbd'),
        p_(mark_ 'Highlighted'),
      ]),
      h3_('Heading 3'),
      p_('Integer bibendum malesuada libero vel eleifend. Fusce iaculis turpis ipsum, at efficitur sem scelerisque vel. Aliquam auctor diam ut purus cursus fringilla. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos.'),
      h4_('Heading 4'),
      p_('Cras fermentum velit vitae auctor aliquet. Nunc non congue urna, at blandit nibh. Donec ac fermentum felis. Vivamus tincidunt arcu ut lacus hendrerit, eget mattis dui finibus.'),
      h5_('Heading 5'),
      p_('Donec nec egestas nulla. Sed varius placerat felis eu suscipit. Mauris maximus ante in consequat luctus. Morbi euismod sagittis efficitur. Aenean non eros orci. Vivamus ut diam sem.'),
      h6_('Heading 6'),
      p_('Ut sed quam non mauris placerat consequat vitae id risus. Vestibulum tincidunt nulla ut tortor posuere, vitae malesuada tortor molestie. Sed nec interdum dolor. Vestibulum id auctor nisi, a efficitur sem. Aliquam sollicitudin efficitur turpis, sollicitudin hendrerit ligula semper id. Nunc risus felis, egestas eu tristique eget, convallis in velit.'),
      figure_([
        img_(src: 'https://source.unsplash.com/a562ZEFKW8I/2000x1000', alt: 'Minimal landscape'),
        figcaption_(['Image from', a_('unsplash.com', href: 'https://unsplash.com')])
      ]),
      h3_('Code'),
      code_(div_(<<~RUBY.gsub(/^ /, '&nbsp;').gsub(/\n/, '<br>').html_safe))
        def method_name
          1 + 1
        end
      RUBY
    ]),
    section_('#buttons', [
      h2_('Buttons'),
      div_('.grid', [
        button_('Primary'),
        button_('.secondary', 'Secondary'),
        button_('.contrast', 'Contrast'),
      ]),
      div_('.grid', [
        button_('.outline', 'Primary outline'),
        button_('.outline.secondary', 'Secondary outline'),
        button_('.outline.contrast', 'Contrast outline'),
      ]),
    ]),
    section_('#form', [
      form_([
        h2_('Form elements'),
        label_('Search', for: 'search'),
        input_('#search', name: 'search', type: 'search', placeholder: 'Search'),
        label_('Text', for: 'text'),
        input_('#text', name: 'text', type: 'text', placeholder: 'Text'),
        small_('Curabitur consequat lacus at lacus porta finibus.'),
        label_('Select', for: 'select'),
        select_('#select', name: 'select', required: true) {[
          option_('Select…', value: '', selected: true),
          option_('…'),
        ]},
        label_(for: 'file') {[
          'File browser',
          input_('#file', name: 'file', type: 'file')
        ]},
        label_(for: 'range') {[
          'Range slider',
          input_('#range', name: 'range', type: 'range', min: 0, max: 100, value: 50)
        ]},
        div_('.grid', [
          label_(for: 'valid') {[
            'Valid',
            input_('#valid', name: 'valid', type: 'text', placeholder: 'Valid', 'aria-invalid': false),
          ]},
          label_(for: 'invalid') {[
            'Invalid',
            input_('#invalid', name: 'invalid', type: 'text', placeholder: 'Invalid', 'aria-invalid': true)
          ]},
          label_(for: 'disabled') {[
            'Disabled',
            input_('#disabled', name: 'disabled', type: 'text', placeholder: 'Disabled', disabled: true)
          ]},
        ]),
        div_('.grid', [
          label_(for: 'date') {[
            'Date',
            input_('#date', name: 'date', type: 'date')
          ]},
          label_(for: 'time') {[
            'Time',
            input_('#time', name: 'time', type: 'time')
          ]},
          label_(for: 'color') {[
            'Color',
            input_('#color', name: 'color', type: 'color', value: '#0eaaaa')
          ]},
        ]),
        div_('.grid', [
          fieldset_([
            legend_(strong_ 'Checkboxes'),
            label_(for: 'checkbox-1') {[
              input_('#checkbox-1', name: 'checkbox-1', type: 'checkbox', checked: true),
              'Checkbox'
            ]},
            label_(for: 'checkbox-2') {[
              input_('#checkbox-2', name: 'checkbox-2', type: 'checkbox'),
              'Checkbox'
            ]},
          ]),
          fieldset_([
            legend_(strong_ 'Radio buttons'),
            label_(for: 'radio-1') {[
              input_('#radio-1', name: 'radio', type: 'radio', value: 'radio-1', checked: true),
              'Radio button'
            ]},
            label_(for: 'radio-2') {[
              input_('#radio-2', name: 'radio', type: 'radio', value: 'radio-2'),
              'Radio button'
            ]},
          ]),
          fieldset_([
            legend_(strong_ 'Switches'),
            label_(for: 'switch-1') {[
              input_('#switch-1', name: 'switch-1', type: 'checkbox', role: 'switch', checked: true),
              'Switch'
            ]},
            label_(for: 'switch-2') {[
              input_('#switch-2', name: 'switch-2', type: 'checkbox', role: 'switch'),
              'Switch'
            ]},
          ]),
        ]),
        input_(type: 'reset', value: 'Reset'),
        input_(type: 'submit', value: 'Submit'),
      ])
    ]),
    section_('#tables', [
      h2_('Tables'),
      figure_(
        table_(role: 'grid') {[
          thead_(
            tr_([
              th_(scope: 'col', text: '#'),
              th_('Heading', scope: 'col', times: 7),
            ])
          ),
          tbody_([
            tr_([
              th_(1, scope: 'row'),
              td_('Cell', times: 7),
            ]),
            tr_([
              th_(2, scope: 'row'),
              td_('Cell', times: 7),
            ]),
            tr_([
              th_(3, scope: 'row'),
              td_('Cell', times: 7),
            ]),
          ])
        ]}
      )
    ]),
    section_('#accordions', [
      h2_('Accordions'),
      details_([
        summary_('Accordion 1'),
        p_('Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque urna diam, tincidunt nec porta sed, auctor id velit. Etiam venenatis nisl ut orci consequat, vitae tempus quam commodo. Nulla non mauris ipsum. Aliquam eu posuere orci. Nulla convallis lectus rutrum quam hendrerit, in facilisis elit sollicitudin. Mauris pulvinar pulvinar mi, dictum tristique elit auctor quis. Maecenas ac ipsum ultrices, porta turpis sit amet, congue turpis.'),
      ]),
      details_(open: true) {[
        summary_('Accordion 2'),
        ul_([
          li_('Vestibulum id elit quis massa interdum sodales.'),
          li_('Nunc quis eros vel odio pretium tincidunt nec quis neque.'),
          li_('Quisque sed eros non eros ornare elementum.'),
          li_('Cras sed libero aliquet, porta dolor quis, dapibus ipsum.'),
        ]),
      ]}
    ]),
    article_('#article', [
      h2_('Article'),
      p_('Nullam dui arcu, malesuada et sodales eu, efficitur vitae dolor. Sed ultricies dolor non ante vulputate hendrerit. Vivamus sit amet suscipit sapien. Nulla iaculis eros a elit pharetra egestas. Nunc placerat facilisis cursus. Sed vestibulum metus eget dolor pharetra rutrum.'),
      footer_(small_ 'Duis nec elit placerat, suscipit nibh quis, finibus neque.'),
    ]),
    section_('#progress', [
      h2_('Progress bar'),
      progress_('#progress-1', value: 25, max: 100),
      progress_('#progress-2', indeterminate: true),
    ]),
    section_('#loading', [
      h2_('Loading'),
      article_('aria-busy': true),
      button_('Please wait…', 'aria-busy': true)
    ])
  ]),
  footer_('.container', footer_text)
)
