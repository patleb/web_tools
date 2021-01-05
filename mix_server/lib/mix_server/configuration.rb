module MixServer
  has_config do
    attr_writer :available_providers

    def available_providers
      @available_providers ||= {
        localhost: 10,
        vagrant: 20,
        aws: 30,
        digital_ocean: 40,
        azure: 50,
        ovh: 60,
        compute_canada: 70
      }
    end
  end
end
