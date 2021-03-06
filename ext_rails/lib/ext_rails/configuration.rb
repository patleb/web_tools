module ExtRails
  has_config do
    attr_accessor :i18n_debug
    attr_writer :sql_debug
    attr_writer :params_debug
    attr_writer :skip_discard
    attr_writer :excluded_models

    def sql_debug?
      return @sql_debug if defined? @sql_debug
      @sql_debug = Rails.env.development? || Rails.env.test? if defined? Rails
    end

    def params_debug?
      return @params_debug if defined? @params_debug
      @params_debug = Rails.env.dev_or_test?
    end

    def skip_discard?
      return @skip_discard if defined? @skip_discard
      @skip_discard = ENV['SKIP_DISCARD'].to_b
    end

    def excluded_models
      @excluded_models ||= Set.new
    end
  end
end
