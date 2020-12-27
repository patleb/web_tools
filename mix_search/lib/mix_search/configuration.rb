module MixSearch
  has_config do
    attr_writer :available_types

    def available_types
      @available_types ||= {}
    end
  end
end
