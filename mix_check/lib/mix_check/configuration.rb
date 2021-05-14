module MixCheck
  has_config do
    attr_writer :available_types
    attr_writer :available_workers

    def available_types
      @available_types ||= {
        'Checks::Postgres::Database' => 1,
        'Checks::Linux::Host' => 2,
      }
    end

    def available_workers
      @available_workers ||= ['ruby', 'postgres']
    end
  end
end
