module MixTask
  has_config do
    attr_writer :yml_path
    attr_writer :admin_names
    attr_writer :available_names
    attr_writer :durations_max_size

    def yml_path
      @yml_path ||= Rails.root.join('config/tasks.yml')
    end

    def admin_names
      @admin_names ||= []
    end

    def available_names
      @available_names ||= {
        'try:send_email'       => 100,
        'try:send_email_later' => 102,
        'try:raise_exception'  => 104,
        'try:sleep'            => 106,
        'try:sleep_long'       => 108,
      }
    end

    def durations_max_size
      @durations_max_size ||= 20
    end
  end
end
