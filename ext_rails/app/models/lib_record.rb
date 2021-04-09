class LibRecord < ActiveRecord::Base
  include AsLibRecord

  self.abstract_class = true
end
