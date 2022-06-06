h_(
  div_('.hero', 'data-theme': 'dark') {[
    nav_('.container-fluid', [
      ul_(
        li_(brand)
      ),
      ul_([
        li_(theme_menu(direction: 'rtl', role: 'link', class: 'contrast')),
        li_(examples_menu(direction: 'rtl', role: 'link', class: 'contrast')),
      ]),
    ]),
    header_('.container', [
      hgroup_([
        h1_('Company'),
        h2_('A classic company or blog layout with a sidebar'),
      ]),
      p_(a_ 'Call to action', href: '#', role: 'button'),
    ])
  ]},
  main_('.container',
    div_('.grid', [
      section_([
        hgroup_([
          h2_('Ut sit amet sem ut velit'),
          h3_('Quisque mi est'),
        ]),
        p_('Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque lobortis est vel velit bibendum ultrices. Sed aliquam tortor vel odio fermentum ullamcorper eu vitae neque. Sed non diam at tellus venenatis viverra. Vestibulum et leo laoreet arcu tempor eleifend venenatis ac leo. Pellentesque euismod justo sed nisl sollicitudin varius. Duis venenatis nisl sit amet ante rutrum posuere. Etiam nec ullamcorper leo, sed placerat mauris.'),
        figure_([
          img_(src: 'https://source.unsplash.com/3Ijt7UkSBYE/1500x750', alt: 'Architecture'),
          figcaption_(['Image from', a_('unsplash.com', href: 'https://unsplash.com')])
        ]),
        h3_('Nulla augue metus'),
        p_('Pacilisis sed ante ut, posuere volutpat quam. Maecenas maximus blandit mi ac finibus. Proin quis lacinia tellus. Aliquam erat volutpat. Aliquam erat volutpat. Phasellus suscipit nisi augue, id accumsan tortor auctor ut. Duis odio arcu, egestas nec nulla vel, fermentum bibendum ex.'),
        h3_('Sed purus sapien, porta a cursus sed, maximus et metus.'),
        p_('Phasellus molestie ante sed massa bibendum, eget tempus ex sollicitudin. Vestibulum libero nulla, porttitor nec faucibus et, scelerisque eget quam. Nullam finibus tempor dui, vel congue urna condimentum ac. Fusce ultricies mauris justo, nec vulputate mauris pulvinar eu. Sed tempus ligula lorem, at tincidunt risus mollis non. Quisque et turpis sit amet sapien gravida ullamcorper in eu velit. Curabitur luctus ornare finibus. Proin tempor nulla sagittis est fermentum dapibus. Vestibulum posuere mattis congue. Ut porttitor id sem euismod tristique. Quisque mi est, posuere nec lorem eu, vulputate vehicula diam. Nullam scelerisque, libero posuere efficitur bibendum, urna odio finibus lorem, sed volutpat dolor ligula in dolor. Suspendisse suscipit efficitur neque, ut porta tellus mollis vel. Nam consequat arcu ac tellus porta, nec egestas orci sodales.'),
      ]),
      aside_([
        a_(img_(src: 'https://source.unsplash.com/T5nXYXCf50I/1500x750', alt: 'Architecture'), href: '#', 'aria-label': 'Example'),
        p_([
          a_('Donec sit amet', href: '#'),
          br_,
          small_('Class aptent taciti sociosqu ad litora torquent per conubia nostra')
        ]),
        a_(img_(src: 'https://source.unsplash.com/tb4heMa-ZRo/1500x750', alt: 'Architecture'), href: '#', 'aria-label': 'Example'),
        p_([
          a_('Suspendisse potenti', href: '#'),
          br_,
          small_('Proin non condimentum tortor. Donec in feugiat sapien.')
        ]),
        a_(img_(src: 'https://source.unsplash.com/Ru3Ap8TNcsk/1500x750', alt: 'Architecture'), href: '#', 'aria-label': 'Example'),
        p_([
          a_('Nullam lobortis placerat aliquam', href: '#'),
          br_,
          small_('Maecenas vitae nibh blandit dolor commodo egestas vel eget neque. Praesent semper justo orci, vel imperdiet mi auctor in.')
        ]),
      ])
    ])
  ),
  section_('aria-label': 'Subscribe example') {
    div_('.container',
      article_([
        hgroup_([
          h2_('Subscribe'),
          h3_('Litora torquent per conubia nostra'),
        ]),
        form_('.grid', [
          input_(type: 'text', id: 'firstname', name: 'firstname', placeholder: 'First name', 'aria-label': 'First name', required: true),
          input_(type: 'email', id: 'email', name: 'email', placeholder: 'Email address', 'aria-label': 'Email address', required: true),
          button_('Subscribe', type: 'submit')
        ]),
      ])
    )
  },
  footer_('.container', footer_text)
)
