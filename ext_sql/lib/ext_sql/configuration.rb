module ExtSql
  has_config do
    attr_writer :debug

    def debug?
      return @debug if defined? @debug
      @debug = Rails.env.development? || Rails.env.test? if defined? Rails
    end
  end
end
