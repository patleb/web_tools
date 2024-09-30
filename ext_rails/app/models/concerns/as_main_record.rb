module AsMainRecord
  extend ActiveSupport::Concern

  included do
    establish_main_connection
  end

  class_methods do
    def establish_main_connection
      establish_connection_for(:main)
    end
  end
end
