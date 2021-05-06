module MixCheck
  has_config do
    attr_writer :available_types

    def available_types
      @available_types ||= {
        'Checks::Postgres::Database' => 1,
        'Checks::Linux::Host' => 2,
      }
    end
  end
end
