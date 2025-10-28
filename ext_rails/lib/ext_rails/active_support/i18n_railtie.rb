MonkeyPatch.add{['activesupport', 'lib/active_support/i18n_railtie.rb', '2d55cfbbce8ecaba1be658d8c9acfd949c3a4dac11bf635107dbf7f4444d1cdc']}

I18n::Railtie.class_eval do
  class << self
    alias_method :initialize_i18n_without_order, :initialize_i18n
    def initialize_i18n(app)
      return if @i18n_inited
      order = app.send(:ordered_railties).flatten.map(&:try.with(:root)).map.with_index.to_h
      app.config.i18n.railties_load_path.sort_by! do |paths|
        order[paths.ivar(:@root).path]
      end
      initialize_i18n_without_order(app)
    end
  end
end
