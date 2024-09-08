module MixSearch
  has_config do
    attr_writer :available_types
    attr_writer :tokens_limit

    def available_types
      @available_types ||= {}
    end

    def tokens_limit
      @tokens_limit ||= 100
    end
  end
end
