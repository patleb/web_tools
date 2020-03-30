module MixCore
  has_config do
    attr_accessor :i18n_debug
    attr_writer :params_debug
    attr_writer :rescue_500
    attr_writer :skip_discard

    def params_debug
      return @params_debug if defined? @params_debug
      @params_debug = Rails.env.dev_or_test?
    end

    def rescue_500
      return @rescue_500 if defined? @rescue_500
      @rescue_500 = !Rails.env.test?
    end

    def skip_discard?
      return @skip_discard if defined? @skip_discard
      @skip_discard = ENV['SKIP_DISCARD'].to_b
    end
  end
end
