class ActiveRecord::Main < ActiveRecord::Base
  include AsMainRecord

  self.abstract_class = true
end
