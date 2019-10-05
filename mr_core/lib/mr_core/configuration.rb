module MrCore
  has_config do
    attr_accessor :i18n_debug
    attr_writer :params_debug
    attr_writer :rescue_500

    def params_debug
      return @params_debug if defined? @params_debug
      @params_debug = Rails::Env.dev_or_test?
    end

    def rescue_500
      return @rescue_500 if defined? @rescue_500
      @rescue_500 = !Rails.env.test?
    end
  end
end
