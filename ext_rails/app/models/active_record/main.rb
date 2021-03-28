class ActiveRecord::Main < ActiveRecord::Base
  self.abstract_class = true
  establish_main_connection
end
