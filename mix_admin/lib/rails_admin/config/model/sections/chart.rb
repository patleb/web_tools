# Configuration of the navigation view
class RailsAdmin::Config::Model::Sections::Chart < RailsAdmin::Config::Model::Sections::Base
  register_instance_option :choose? do
    false
  end

  register_instance_option :choose_prefix do
    nil
  end

  register_instance_option :type do
    :area
  end

  register_instance_option :options do
    {}
  end

  register_instance_option :refresh_rate do
    false
  end

  register_instance_option :field_default do
    nil
  end

  register_instance_option :group_by do
    :created_at
  end

  register_instance_option :max_range do
    nil # TODO 1.week
  end

  register_instance_option :max_size do
    288
  end

  register_instance_option :y2_ratio do
    10
  end

  register_instance_option :map do
    nil
  end

  register_instance_option :work_mem do
    nil
  end
end
