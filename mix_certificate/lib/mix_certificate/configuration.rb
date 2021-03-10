module MixCertificate
  has_config do
    attr_writer :available_types

    def available_types
      @available_types ||= {
        'Certificates::LetsEncrypt' => 10,
      }
    end
  end
end
