module MrGlobal
  has_config do
    attr_writer :expires_in, :touch_in

    def expires_in
      @expires_in ||= 1.month
    end

    def touch_in
      @touch_in ||= expires_in * 0.5
    end
  end
end
