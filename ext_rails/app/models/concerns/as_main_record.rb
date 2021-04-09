module AsMainRecord
  extend ActiveSupport::Concern

  included do
    establish_main_connection
  end
end
