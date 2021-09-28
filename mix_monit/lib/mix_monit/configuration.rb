module MixMonit
  has_config do
    attr_writer :available_workers

    def available_workers
      @available_workers ||= ['ruby', 'postgres']
    end
  end
end
