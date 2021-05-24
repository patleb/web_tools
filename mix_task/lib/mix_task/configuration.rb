require 'mix_setting'

module MixTask
  has_config do
    attr_writer   :available_names
    attr_writer   :durations_max_size
    attr_accessor :keep_install_migrations

    def available_names
      @available_names ||= {}
    end

    def durations_max_size
      @durations_max_size ||= 20
    end
  end
end
