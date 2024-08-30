module MixGlobal
  has_config do
    attr_writer :parent_model
    attr_writer :expires_in
    attr_writer :touch_in

    def parent_model
      @parent_model ||= 'LibMainRecord'
    end

    def expires_in
      @expires_in ||= 1.month
    end

    def touch_in
      @touch_in ||= expires_in * 0.5
    end
  end
end
