module ExtBootstrap
  module BootswatchHelper
    BOOTSWATCH_FONTS = {
      cyborg: 'https://fonts.googleapis.com/css?family=Roboto:400,700&display=swap',
      paper:  'https://fonts.googleapis.com/css?family=Roboto:300,400,500,700&display=swap',
    }.freeze

    def preload_link_tag_bootswatch_fonts(theme)
      preload_link_tag(BOOTSWATCH_FONTS[theme.to_sym], as: 'style')
    end
  end
end
