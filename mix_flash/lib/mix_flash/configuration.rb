module MixFlash
  has_config do
    attr_accessor :flash_expires_in

    def flash_expires_in
      @expires_in ||= 1.week
    end
  end
end
