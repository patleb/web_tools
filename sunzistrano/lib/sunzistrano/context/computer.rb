module Sunzistrano
  Context.class_eval do
    alias_method :attributes_without_computer, :attributes
    def attributes
      attributes_without_computer.merge(computer: env.computer?)
    end

    def computer_path(*)
      provision_path(BASH_DIR, *)
    end

    alias_method :sudo_without_computer, :sudo
    def sudo
      return true if computer && sun.task.blank?
      sudo_without_computer
    end
  end
end
