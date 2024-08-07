module MixTask
  has_config do
    attr_writer   :admin_names
    attr_writer   :available_names
    attr_writer   :durations_max_size

    def admin_names
      @admin_names ||= []
    end

    def available_names
      @available_names ||= {}
    end

    def durations_max_size
      @durations_max_size ||= 20
    end
  end
end
