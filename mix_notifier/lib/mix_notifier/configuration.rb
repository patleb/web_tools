module MixNotifier
  has_config do
    attr_writer :skip_notice

    def skip_notice
      return @skip_notice if defined? @skip_notice
      @skip_notice = Rails.env.development? if defined? Rails
    end
  end
end
